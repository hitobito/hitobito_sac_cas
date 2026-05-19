# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Tours::State
  extend ActiveSupport::Concern

  include Events::State

  RECEIVER_JOB_MAP = {
    mailing_list_people: Event::Tour::MailingListPeopleEmailDispatchJob,
    assigned_freigabe_komitees: Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob,
    leaders: Event::Tour::LeadersEmailDispatchJob,
    participants_confirmed: Event::Tour::ParticipantsEmailDispatchJob,
    participants_unconfirmed: Event::Tour::ParticipantsEmailDispatchJob,
    participants_participated: Event::Tour::ParticipantsEmailDispatchJob,
    participants: Event::Tour::ParticipantsEmailDispatchJob
  }.with_indifferent_access

  included do # rubocop:todo Metrics/BlockLength
    attr_accessor :receiver_options

    # key: current state
    # value: array of possible next states
    self.state_transitions = {
      draft: [:review, :approved],
      review: [:draft, :approved],
      approved: [:draft, :published, :canceled],
      published: [:draft, :approved, :ready, :canceled],
      ready: [:published, :closed, :canceled],
      closed: [:ready],
      canceled: [:approved, :published, :ready]
    }.freeze

    # Define methods to query if a tour is in the given state.
    # eg tour.canceled?
    possible_states.each do |state|
      define_method :"#{state}?" do
        self.state == state
      end
    end

    after_update :handle_state_transition, if: :saved_change_to_state?
  end

  private

  def handle_state_transition
    method_name = :"handle_state_transition_to_#{state}"
    back_method_name = :"handle_state_transition_back_to_#{state}"

    if state_comes_before?(state_before_last_save, state)
      send(method_name) if respond_to?(method_name, true)
    elsif respond_to?(back_method_name, true)
      send(back_method_name)
    end
  end

  def handle_state_transition_to_published
    send_emails(subito? ? :publication_subito : :publication)
  end

  def handle_state_transition_back_to_published
    send_emails(:back_to_published)
  end

  def handle_state_transition_to_ready
    participations.where(state: :assigned).update_all(state: :summoned)
    participations.where(state: [:unconfirmed, :applied]).update_all(state: :rejected)

    return if no_emails?

    receiver_options.each do |option|
      mailer_method = (option == "participants_unconfirmed") ?
          :participation_reject : :participation_summon

      enqueue_email_job(option, mailer_method)
    end

    unless receiver_options.include?("participants_unconfirmed")
      Event::Tour::InvolvedPeopleEmailDispatchJob.new(:participation_summon, id).enqueue!
    end
  end

  def handle_state_transition_back_to_ready
    participations.where(state: :annulled)
      .update_all("state = previous_state, active = TRUE, previous_state = NULL")

    send_emails(:back_to_ready)
  end

  def handle_state_transition_to_closed
    participations.where(state: :summoned).update_all(state: :attended)

    send_emails(:closing)
  end

  def handle_state_transition_to_canceled
    mailer_method = case canceled_reason.to_sym
    when :no_leader then :canceled_no_leader
    when :weather then :canceled_weather
    when :minimum_participants then :canceled_minimum_participants
    end

    send_emails(mailer_method)

    participations.update_all("previous_state = state, active = FALSE, state = 'annulled'")
  end

  def handle_state_transition_back_to_draft
    send_emails(:back_to_draft)
  end

  def handle_state_transition_back_to_approved
    send_emails(:back_to_approved)
  end

  def send_emails(mailer_method)
    return if no_emails?

    receiver_options.each do |option|
      enqueue_email_job(option, mailer_method)
    end
    Event::Tour::InvolvedPeopleEmailDispatchJob.new(mailer_method, id).enqueue!
  end

  def enqueue_email_job(receiver_option, mailer_method)
    states = participant_states(receiver_option)
    args = [mailer_method, id]
    args << states if states.present?

    RECEIVER_JOB_MAP.fetch(receiver_option).new(*args).enqueue!
  end

  def no_emails?
    receiver_options.nil? || receiver_options.include?("none")
  end

  def participant_states(receiver_option)
    case receiver_option.to_sym
    when :participants_unconfirmed then ["unconfirmed", "applied"]
    when :participants_confirmed then ["assigned"]
    when :participants_participated then ["attended"]
    when :participants then ["unconfirmed", "applied", "assigned", "summoned"]
    else []
    end
  end
end
