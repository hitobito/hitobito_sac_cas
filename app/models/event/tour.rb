# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Tour < Event
  include ::Events::Tours::State

  WEAK_VALIDATION_STATES = %w[draft].freeze

  self.used_attributes += [:state, :display_booking_info, :waiting_list, :minimum_participants,
    :summit, :ascent, :descent, :season, :internal_comment, :minimum_age, :maximum_age,
    :tourenportal_link, :subito]
  self.used_attributes -= [:motto, :waiting_list, :required_contact_attrs, :hidden_contact_attrs,
    :signature, :signature_confirmation, :signature_confirmation_text, :guest_limit]

  self.role_types = [
    Event::Role::Leader,
    Event::Role::AssistantLeader,
    Event::Role::Helper,
    Event::Tour::Role::Participant
  ]

  self.supports_applications = true
  self.supports_invitations = false

  self.possible_participation_states = %w[unconfirmed applied rejected assigned
    attended absent canceled annulled]
  self.active_participation_states = %w[assigned attended]
  self.revoked_participation_states = %w[rejected canceled absent annulled]
  self.countable_participation_states = %w[unconfirmed applied assigned attended absent]

  # Used for Event::TourResource
  attr_accessor :leaders

  belongs_to :fitness_requirement, optional: true

  has_and_belongs_to_many :disciplines,
    join_table: :events_disciplines,
    class_name: "Event::Discipline",
    foreign_key: :event_id,
    before_add: :prevent_association_changes_in_weak_validation_state,
    before_remove: :prevent_association_changes_in_weak_validation_state

  has_and_belongs_to_many :target_groups,
    join_table: :events_target_groups,
    class_name: "Event::TargetGroup",
    foreign_key: :event_id,
    before_add: :prevent_association_changes_in_weak_validation_state,
    before_remove: :prevent_association_changes_in_weak_validation_state

  has_and_belongs_to_many :technical_requirements,
    join_table: :events_technical_requirements,
    class_name: "Event::TechnicalRequirement",
    foreign_key: :event_id,
    before_add: :prevent_association_changes_in_weak_validation_state,
    before_remove: :prevent_association_changes_in_weak_validation_state

  has_and_belongs_to_many :traits,
    join_table: :events_traits,
    class_name: "Event::Trait",
    foreign_key: :event_id

  ### VALIDATIONS

  before_save :prevent_changes_in_weak_validation_state, unless: :weak_validation_state?
  validates :state, inclusion: possible_states
  validates :disciplines, :target_groups, :technical_requirements,
    :fitness_requirement, :season, presence: {unless: :weak_validation_state?}

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

  def weak_validation_state?
    state.blank? || WEAK_VALIDATION_STATES.include?(state)
  end

  def dates_changed?
    dates.any? {
      _1.saved_change_to_start_at? ||
        _1.saved_change_to_finish_at ||
        _1.new_record? ||
        _1.marked_for_destruction?
    }
  end

  private

  def prevent_changes_in_weak_validation_state
    [:subito, :fitness_requirement_id, :season].each do |attribute|
      send(:"restore_#{attribute}!")
    end
  end

  def prevent_association_changes_in_weak_validation_state(record)
    throw :abort unless weak_validation_state?
  end
end
