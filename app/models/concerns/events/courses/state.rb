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
     canceled: [:application_open],
     closed: [:ready]}.freeze

  APPLICATION_OPEN_STATES = %w[application_open application_paused].freeze

  included do
    self.possible_states = SAC_COURSE_STATES.keys.collect(&:to_s)

    validate :assert_valid_state_change, if: :state_changed?
    before_create :set_default_state
    before_save :adjust_state, if: :application_closing_at_changed?
    after_update :send_application_published_email, if: :state_changed_from_created_to_application_open?
    after_update :send_application_paused_email, if: :state_changed_to_application_paused?
    after_update :send_application_closed_email, if: :state_changed_to_application_closed?
    after_update :notify_rejected_participants, if: :state_changed_to_assignment_closed?
    after_update :summon_assigned_participants, if: :state_changed_from_assignment_closed_to_ready?
    after_update :cancel_invoices, if: :state_changed_to_canceled?
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

  private

  def assert_valid_state_change
    unless available_states(state_was).include?(state.to_sym)
      errors.add(:state, "State cannot be changed from #{state_was} to #{state}")
    end
  end

  def set_default_state
    self.state = :created
  end

  def state_changed_to_assignment_closed?
    saved_change_to_attribute(:state)&.second == "assignment_closed"
  end

  def state_changed_to_application_paused?
    saved_change_to_attribute(:state)&.second == "application_paused"
  end

  def state_changed_to_application_closed?
    saved_change_to_attribute(:state)&.second == "application_closed"
  end

  def state_changed_from_assignment_closed_to_ready?
    saved_change_to_attribute(:state) == ["assignment_closed", "ready"]
  end

  def state_changed_from_created_to_application_open?
    saved_change_to_attribute(:state) == ["created", "application_open"]
  end

  def state_changed_to_canceled?
    saved_change_to_attribute(:state)&.second == "canceled"
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
    end
    assigned_participants.update_all(state: :summoned)
  end

  def cancel_invoices
    course_invoices.each do |invoice|
      Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
    end
  end

  def course_invoices
    ExternalInvoice::Course.where(link: self)
  end

  def assigned_participants
    participations.where(state: :assigned)
  end

  def send_application_published_email
    leaders.each do |leader|
      Event::PublishedMailer.notice(self, leader).deliver_later
    end
  end

  def send_application_paused_email
    Event::ApplicationPausedMailer.notice(self).deliver_later if groups.first.course_admin_email.present?
  end

  def send_application_closed_email
    Event::ApplicationClosedMailer.notice(self).deliver_later if groups.first.course_admin_email.present?
  end

  def adjust_state
    if APPLICATION_OPEN_STATES.include?(state) && application_closing_at.try(:past?)
      self.state = "application_closed"
    end

    if application_closed? && %w[today? future?].any? { application_closing_at.try(_1) }
      self.state = "application_open"
    end
  end
end
