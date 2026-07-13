# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  EDITABLE_PARTICIPATION_STATES = %w[assigned attended absent].freeze
  RELEASE_ROLE_TYPES = [
    Group::SektionsTourenUndKurse::Tourenchef,
    Group::SektionsTourenUndKurse::TourenchefSommer,
    Group::SektionsTourenUndKurse::TourenchefWinter,
    Group::FreigabeKomitee::Pruefer,
    Group::SektionsFunktionaere::Finanzen
  ].map(&:sti_name).freeze

  TRANSITION_MAIL_DEFINITIONS = {
    [:draft, "forward"] => {mailer: :submitted, recipients: :mail_recipient},
    [:review, "forward"] => {mailer: :approved, recipients: :mail_recipient},
    [:approved, "forward"] => {mailer: :payout_recorded, recipients: :submitter},
    [:review, "reject"] => {mailer: :rejected, recipients: :submitter},
    [:approved, "reject"] => {mailer: :payout_rejected, recipients: :approver}
  }.freeze

  attr_reader :report
  attr_accessor :current_user

  delegate :event, :submitter, :approver, to: :report

  attribute :review, :string
  attribute :remarks, :string
  attribute :status_action, :string, default: "keep"
  attribute :mail_recipient_id, :integer

  validate :assert_participation_states_editable
  validate :assert_mail_recipient_present_when_forwarding

  def initialize(report, current_user = nil, attrs = {})
    @report = report
    @current_user = current_user
    super({review: report.review, remarks: report.remarks, **attrs})
  end

  def save
    return false unless valid?

    original_status = report.status
    captured_recipients = capture_mail_recipients(original_status)

    success = report.transaction do
      unless report.update(review:, remarks:) &&
          save_participations && apply_status_change(original_status)
        raise ActiveRecord::Rollback
      end
      true
    end

    deliver_status_emails(original_status, captured_recipients) if success
    success
  end

  def tour_completed?
    [:ready, :closed].include?(event.state.to_sym)
  end

  def possible_mail_recipients
    sektion = event.groups.first.layer_group
    group_ids = sektion.groups_in_same_layer.select(:id)

    Person
      .joins(:roles)
      .merge(Role.active)
      .where(roles: {type: RELEASE_ROLE_TYPES, group_id: group_ids})
      .distinct
      .order_by_name
      .select("people.*")
  end

  attr_writer :participations_attributes

  def participations
    @participations ||= event
      .participations
      .includes(:event, :roles)
      .where.not(state: ["rejected", "applied", "unconfirmed"])
      .order_by_role(event)
  end

  def editable_participation_state?(participation)
    EDITABLE_PARTICIPATION_STATES.include?(participation.state)
  end

  def participation_state_labels(participation)
    Event::Participation.state_labels(participation)
      .slice(*EDITABLE_PARTICIPATION_STATES
      .map(&:to_sym))
      .to_a
  end

  private

  def assert_participation_states_editable
    return unless @participations_attributes

    @participations_attributes.each do |id, attrs|
      next if attrs[:state].blank?

      unless editable_participation_state?(participation_by_id[id.to_i])
        errors.add(:base, :participation_state_not_editable)
      end
    end
  end

  def assert_mail_recipient_present_when_forwarding
    return unless status_action == "forward"
    return if report.status == :approved

    errors.add(:mail_recipient_id, :blank) if mail_recipient_id.blank?
  end

  def save_participations
    return true unless @participations_attributes

    @participations_attributes.all? do |id, attrs|
      participation = participation_by_id[id.to_i]
      participation.update(attrs)
    end
  end

  def participation_by_id
    @participation_by_id ||= participations.index_by(&:id)
  end

  def apply_status_change(original_status)
    case status_action
    when "forward" then apply_forward(original_status)
    when "reject" then apply_reject(original_status)
    else true
    end
  end

  def apply_forward(original_status)
    attrs = case original_status
    when :draft then {submitted_at: Time.zone.now, submitter: current_user}
    when :review then {approved_at: Time.zone.now, approver: current_user}
    when :approved then {paid_at: Time.zone.now, payer: current_user}
    else return true
    end
    report.update(attrs)
  end

  def apply_reject(original_status)
    attrs = case original_status
    when :review then {submitted_at: nil, submitter_id: nil}
    when :approved then {approved_at: nil, approver_id: nil}
    else return true
    end
    report.update(attrs)
  end

  def capture_mail_recipients(original_status)
    recipients_method = mail_definition(original_status)[:recipients]

    return unless recipients_method

    [send(recipients_method)].compact
  end

  def deliver_status_emails(original_status, recipients) # rubocop:disable Metrics/CyclomaticComplexity
    mailer_method = mail_definition(original_status)[:mailer]

    return if recipients.blank? || mailer_method.nil?

    Event::TourReportMailer.public_send(mailer_method, report, recipients).deliver_later
  end

  def mail_recipient = Person.where(id: mail_recipient_id).first

  def mail_definition(original_status) = TRANSITION_MAIL_DEFINITIONS[[original_status,
    status_action]] || {}
end
