# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Courses::State
  extend ActiveSupport::Concern

  # key: current state
  # value: possible next state
  SAC_COURSE_STATES =
    {created: [:application_open],
     application_open: [:application_paused, :created, :canceled],
     application_paused: [:application_open],
     application_closed: [:assignment_closed, :canceled],
     assignment_closed: [:ready, :application_closed, :canceled],
     ready: [:closed, :assignment_closed, :canceled],
     canceled: [:application_open], # BEWARE: canceled means "annulliert" here and matches `annulled` on participation, where `canceled` means "abgemeldet"
     closed: [:ready]}.freeze

  APPLICATION_OPEN_STATES = %w[application_open application_paused].freeze

  included do
    attr_accessor :inform_participants

    self.possible_states = SAC_COURSE_STATES.keys.collect(&:to_s)

    validate :assert_valid_state_change, if: :state_changed?
    validates :canceled_reason, presence: true, if: -> { state_changed_to?(:canceled) }

    before_create :set_default_state
    before_save :adjust_application_state, if: :application_closing_at_changed?
    after_update :send_application_published_email,
      if: -> { saved_change_to_state?(from: "created", to: "application_open") }
    after_update :summon_assigned_participants,
      if: -> { saved_change_to_state?(from: "assignment_closed", to: "ready") }
    after_update :send_application_paused_email, if: -> { state_changed_to?(:application_paused) }
    after_update :send_application_closed_email, if: -> { state_changed_to?(:application_closed) }
    after_update :notify_rejected_participants, if: -> { state_changed_to?(:assignment_closed) }
    after_update :annul_participations, if: -> { state_changed_to?(:canceled) }
    after_update :send_canceled_email, if: -> { state_changed_to?(:canceled) && inform_participants? }
    after_update :send_absent_invoices, if: -> { state_changed_to?(:closed) }
  end

  def available_states(state = self.state)
    SAC_COURSE_STATES[state.to_sym]
  end

  def state_comes_before?(state1, state2)
    states = SAC_COURSE_STATES.keys
    states.index(state1.to_sym) < states.index(state2.to_sym)
  end

  def state_possible?(new_state)
    available_states.any?(new_state.to_sym)
  end

  def send_canceled_email
    return if canceled_reason.nil?

    all_participants.each do |participation|
      Event::CanceledMailer.send(canceled_reason, participation).deliver_later
    end
  end

  private

  def assert_valid_state_change
    unless available_states(state_was).include?(state.to_sym)
      errors.add(:state, "State cannot be changed from #{state_was} to #{state}")
    end
  end

  def set_default_state
    self.state = :created
  end

  def state_changed_to?(new_state)
    saved_change_to_state?(to: new_state.to_s)
  end

  def notify_rejected_participants
    rejected_participants.each do |participation|
      Event::ParticipationMailer.send(:"reject_#{participation.state}", participation).deliver_later
    end
  end

  def rejected_participants
    participations.where(state: %i[applied rejected])
  end

  def summon_assigned_participants
    assigned_participants.each do |participation|
      Event::ParticipationMailer.summon(participation).deliver_later
      unless ExternalInvoice::CourseParticipation.exists?(link: participation)
        ExternalInvoice::CourseParticipation.invoice!(participation)
      end
    end
    assigned_participants.update_all(state: :summoned)
  end

  def assigned_participants
    participants_scope.where(state: :assigned)
  end

  def annul_participations
    all_participants.update_all("previous_state = state, active = FALSE, state = 'annulled'")
    cancel_invoices(all_course_invoices)
  end

  def all_participants # also including not active
    participations
      .joins(:roles)
      .where(event_roles: {type: participant_types.collect(&:sti_name)})
  end

  def cancel_invoices(invoices)
    invoices.each do |invoice|
      Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
    end
  end

  def all_course_invoices
    ExternalInvoice.where(
      link_id: participations.select(:id),
      link_type: Event::Participation.sti_name,
      type: [ExternalInvoice::CourseParticipation, ExternalInvoice::CourseAnnulation].map(&:sti_name)
    )
  end

  def send_application_published_email
    leaders.each do |leader|
      Event::PublishedMailer.notice(self, leader).deliver_later
    end
  end

  def send_application_paused_email
    Event::ApplicationPausedMailer.notice(self).deliver_later if course_admin_email?
  end

  def send_application_closed_email
    Event::ApplicationClosedMailer.notice(self).deliver_later if course_admin_email?
  end

  def send_absent_invoices
    participations.where(state: :absent).find_each do |participation|
      unless ExternalInvoice::CourseAnnulation.exists?(link: participation, total: participation.price)
        cancel_invoices(participation.external_invoices)
        ExternalInvoice::CourseAnnulation.invoice!(participation)
      end
    end
  end

  def adjust_application_state
    if APPLICATION_OPEN_STATES.include?(state) && application_closing_at.try(:past?)
      self.state = "application_closed"
    end

    if application_closed? && %w[today? future?].any? { application_closing_at.try(_1) }
      self.state = "application_open"
    end
  end

  def inform_participants?
    inform_participants.to_i.positive?
  end

  def course_admin_email?
    groups.first.course_admin_email.present?
  end
end
