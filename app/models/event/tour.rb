# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Tour < Event
  include ::Events::State

  self.used_attributes += [:state, :display_booking_info, :waiting_list, :minimum_participants]
  self.used_attributes -= [:motto, :waiting_list, :required_contact_attrs, :hidden_contact_attrs,
    :signature, :signature_confirmation, :signature_confirmation_text]

  self.role_types = [
    Event::Role::Leader,
    Event::Role::AssistantLeader,
    Event::Role::Helper,
    Event::Tour::Role::Participant
  ]

  self.supports_applications = true
  self.supports_invitations = false

  # key: current state
  # value: array of possible next states
  self.state_transitions = {
    draft: [:approved, :canceled],
    approved: [:draft, :published, :canceled],
    published: [:approved, :canceled, :closed],
    canceled: [:draft, :approved, :published], # BEWARE: canceled means "annulliert" here and matches `annulled` on participation, where `canceled` means "abgemeldet"
    closed: [:published]
  }.freeze

  self.possible_participation_states = %w[unconfirmed applied rejected assigned
    attended absent canceled annulled]
  self.active_participation_states = %w[assigned attended]
  self.revoked_participation_states = %w[rejected canceled absent annulled]
  self.countable_participation_states = %w[unconfirmed applied assigned attended absent]

  # Used for Event::TourResource
  attr_accessor :leaders

  ### VALIDATIONS

  validates :state, inclusion: possible_states

  ### INSTANCE METHODS

  # Define methods to query if a course is in the given state.
  # eg course.canceled?
  possible_states.each do |state|
    define_method :"#{state}?" do
      self.state == state
    end
  end

  def state
    super || possible_states.first
  end

  def tentative_application_possible?
    tentative_applications?
  end

  def default_participation_state(participation, for_someone_else = false)
    if participation.application.blank? || for_someone_else
      "assigned"
    elsif places_available? && !automatic_assignment?
      "unconfirmed"
    else
      "applied"
    end
  end
end
