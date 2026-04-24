# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::Event::Participation
  extend ActiveSupport::Concern

  MANUALLY_SENDABLE_LEADERSHIP_MAILS = [
    Event::CourseMailer::PUBLISHED,
    Event::CourseParticipationMailer::LEADER_REMINDER_NEXT_WEEK,
    Event::CourseParticipationMailer::LEADER_REMINDER_8_WEEKS
  ]

  SELF_EMPLOYED_LEADER_ROLES = [
    Group::SacCasKurskader::KursleitungSelbstaendig,
    Group::SacCasKurskader::KursleitungAspirantSelbstaendig,
    Group::SacCasKurskader::KlassenlehrerSelbstaendig,
    Group::SacCasKurskader::KlassenlehrerAspirantSelbstaendig
  ]

  delegate :sac_membership_active?, :membership_years, :membership_number, :correspondence,
    to: :person

  prepended do # rubocop:todo Metrics/BlockLength
    self::MANUALLY_SENDABLE_PARTICIPANT_MAILS.clear
    self::MANUALLY_SENDABLE_PARTICIPANT_MAILS.concat([
      Event::CourseParticipationMailer::SUMMONED_PARTICIPATION,
      Event::CourseParticipationMailer::ASSIGNED,
      Event::CourseParticipationMailer::UNCONFIRMED,
      Event::CourseParticipationMailer::APPLIED,
      Event::CourseParticipationMailer::REJECT_REJECTED_PARTICIPATION,
      Event::CourseParticipationMailer::REJECT_APPLIED_PARTICIPATION,
      Event::CourseParticipationMailer::CANCELED_PARTICIPATION,
      Event::CourseParticipationMailer::REMINDER,
      Event::CourseParticipationMailer::SURVEY,
      Event::CourseParticipationMailer::EVENT_CANCELED_NO_LEADER,
      Event::CourseParticipationMailer::EVENT_CANCELED_MINIMUM_PARTICIPANTS,
      Event::CourseParticipationMailer::EVENT_CANCELED_WEATHER
    ])

    include I18nEnums
    include CapitalizedDependentErrors

    enum :price_category, [:price_member, :price_regular, :price_subsidized, :price_special]

    i18n_enum :invoice_state, ExternalInvoice::STATES, scopes: true, queries: true

    paper_trail_options[:skip] |= ["previous_state"]

    before_validation :round_actual_days
    before_save :update_previous_state, if: :state_changed?

    attr_accessor :adult_consent, :terms_and_conditions, :newsletter, :check_root_conditions

    # rubocop:todo Rails/InverseOf
    has_many :external_invoices, as: :link, dependent: :restrict_with_error
    # rubocop:enable Rails/InverseOf

    validates :adult_consent, :terms_and_conditions, acceptance: {if: :check_root_conditions}
    validates :actual_days, numericality: {greater_than_or_equal_to: 0, allow_blank: true}
    validate :assert_actual_days_size, if: :actual_days_changed?
  end

  def subsidizable?
    event.course? && event.price_subsidized.present? && sac_membership_active?
  end

  def participant_cancelable?
    event.applications_cancelable? && event.state != "annulled" &&
      event.dates.map(&:start_at).min.future?
  end

  def check_root_conditions!
    # set values to false because validates acceptance does not work with nil
    self.adult_consent ||= false
    self.terms_and_conditions ||= false
    self.check_root_conditions = true
  end

  def highest_leader_role_type
    @highest_leader_role_type ||= Event::Course::LEADER_ROLES.find do |type|
      roles.any? { |role| role.type == type }
    end&.demodulize&.underscore
  end

  private

  def round_actual_days
    if new_record? && roles.any? { |r| r.class.participant? }
      self.actual_days ||= event.training_days
    end

    self.actual_days = (actual_days * 2).round / 2.0 if actual_days
  end

  def assert_actual_days_size
    return if actual_days.blank?

    if actual_days > event.total_duration_days
      errors.add(:actual_days, :longer_than_event_duration)
    end
  end

  def update_previous_state
    if %w[canceled annulled].include?(state)
      self.previous_state = state_was
    end
  end

  def state_changed_to_canceled?
    saved_change_to_attribute(:state)&.second == "canceled"
  end
end
