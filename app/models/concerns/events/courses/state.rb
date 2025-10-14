# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Courses::State
  extend ActiveSupport::Concern

  include Events::State

  APPLICATION_OPEN_STATES = %w[application_open application_paused].freeze

  EMAIL_DISPATCH_CONDITIONS = {
    leader_reminder: [:ready],
    survey: [:ready, :closed]
  }

  included do # rubocop:todo Metrics/BlockLength
    attr_accessor :inform_participants, :skip_emails

    # key: current state
    # value: array of possible next states
    self.state_transitions = {
      created: [:application_open],
      application_open: [:application_paused, :created, :canceled],
      application_paused: [:application_open],
      application_closed: [:assignment_closed, :canceled],
      assignment_closed: [:ready, :application_closed, :canceled],
      ready: [:closed, :assignment_closed, :canceled],
      # rubocop:todo Layout/LineLength
      canceled: [:application_open], # BEWARE: canceled means "annulliert" here and matches `annulled` on participation, where `canceled` means "abgemeldet"
      # rubocop:enable Layout/LineLength
      closed: [:ready]
    }.freeze

    # key: current state
    # value: array of possible next states
    self.state_transition_emails_skippable = {
      created: [:application_open],
      assignment_closed: [:ready],
      application_closed: state_transitions[:application_closed]
    }

    before_save :adjust_application_state

    after_update :summon_assigned_participants, if: -> {
      saved_change_to_state?(from: :assignment_closed, to: :ready)
    }
    after_update :annul_participations, if: -> { state_changed_to?(:canceled) }
    after_update :send_absent_invoices, if: -> { state_changed_to?(:closed) }

    with_options unless: :skip_emails do
      after_update :send_application_published_email, if: -> {
        saved_change_to_state?(from: :created, to: :application_open)
      }
      after_update :send_application_paused_email, if: -> { state_changed_to?(:application_paused) }
      after_update :send_application_closed_email, if: -> { state_changed_to?(:application_closed) }
      after_update :notify_rejected_participants, if: -> { state_changed_to?(:assignment_closed) }
      after_update :send_canceled_email, if: -> {
        state_changed_to?(:canceled) && inform_participants?
      }
    end
  end

  def send_canceled_email
    return if canceled_reason.nil?

    participations.find_each do |participation|
      next if participation.previous_state == "canceled"
      Event::CanceledMailer.send(canceled_reason, participation).deliver_later
    end
  end

  def survey_email_possible?
    EMAIL_DISPATCH_CONDITIONS[:survey].include?(state.to_sym)
  end

  def leader_reminder_email_possible?
    EMAIL_DISPATCH_CONDITIONS[:leader_reminder].include?(state.to_sym)
  end

  def any_email_possible?
    EMAIL_DISPATCH_CONDITIONS.values.flatten.any?(state.to_sym)
  end

  private

  def notify_rejected_participants
    rejected_participants.each do |participation|
      Event::ParticipationMailer.send(:"reject_#{participation.state}", participation).deliver_later
    end
  end

  def rejected_participants
    participations.where(state: %i[applied rejected unconfirmed])
  end

  def summon_assigned_participants
    assigned_participants.each do |participation|
      Event::ParticipationMailer.summon(participation).deliver_later unless skip_emails
      if !ExternalInvoice::CourseParticipation.exists?(link: participation) && groups.first.root?
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
    cancel_invoices(open_course_invoices)
  end

  def all_participants # also including not active
    participations
      .joins(:roles)
      .where(event_roles: {type: participant_types.collect(&:sti_name)})
  end

  def cancel_invoices(invoices)
    invoices.each do |invoice|
      invoice.update!(state: :cancelled)
      Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
    end
  end

  def open_course_invoices
    ExternalInvoice.where(
      link_id: participations.select(:id),
      link_type: Event::Participation.sti_name,
      state: [:draft, :open, :payed],
      type: [ExternalInvoice::CourseParticipation,
        ExternalInvoice::CourseAnnulation].map(&:sti_name)
    )
  end

  def send_application_published_email
    all_leaders.each do |leader|
      Event::PublishedMailer.notice(self, leader).deliver_later
    end
  end

  def all_leaders
    Person.where(id: participations.joins(:roles)
      .where(roles: {type: SacCas::Event::Course::LEADER_ROLES})
      .where(participant_type: Person.sti_name)
      .select(:participant_id))
  end

  def send_application_paused_email
    Event::ApplicationPausedMailer.notice(self).deliver_later if course_admin_email?
  end

  def send_application_closed_email
    Event::ApplicationClosedMailer.notice(self).deliver_later if course_admin_email?
  end

  def send_absent_invoices
    return unless groups.first.root?

    participations.where(state: :absent).find_each do |participation|
      unless ExternalInvoice::CourseAnnulation.exists?(link: participation,
        total: participation.price)
        cancel_invoices(participation.external_invoices)
        ExternalInvoice::CourseAnnulation.invoice!(participation)
      end
    end
  end

  def adjust_application_state # rubocop:todo Metrics/CyclomaticComplexity
    return unless application_closing_at_changed? || state_changed?

    if APPLICATION_OPEN_STATES.include?(state) && application_closing_at&.past?
      self.state = "application_closed"
    end

    if application_closed? && application_closing_at && application_closing_at >= Time.zone.today
      self.state = "application_open"
    end
  end

  def inform_participants?
    inform_participants.to_i.positive?
  end

  def course_admin_email?
    Group.root.course_admin_email.present?
  end
end
