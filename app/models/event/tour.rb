# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Tour < Event
  include ::Events::Tours::State

  WEAK_VALIDATION_STATES = %w[draft].freeze

  PRICE_ATTRIBUTES = %i[price_member price_regular price_special]

  self.used_attributes += [:state, :display_booking_info, :waiting_list, :minimum_participants,
    :summit, :ascent, :descent, :duration_h, :duration_m, :maps, :season, :alternative_route,
    :additional_info, :price_description, :internal_comment, :minimum_age, :maximum_age,
    :tourenportal_link, :subito, *PRICE_ATTRIBUTES]
  self.used_attributes -= [:motto, :waiting_list, :required_contact_attrs, :hidden_contact_attrs,
    :signature, :signature_confirmation, :signature_confirmation_text, :guest_limit, :cost]

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

  has_many :approvals,
    dependent: :destroy,
    class_name: "Event::Approval",
    foreign_key: :event_id,
    inverse_of: :event

  has_and_belongs_to_many :disciplines,
    join_table: :events_disciplines,
    class_name: "Event::Discipline",
    foreign_key: :event_id,
    before_add: :prevent_association_changes_in_weak_validation_state,
    before_remove: :prevent_association_changes_in_weak_validation_state,
    after_add: :track_association_addition,
    after_remove: :track_association_removal

  has_and_belongs_to_many :target_groups,
    join_table: :events_target_groups,
    class_name: "Event::TargetGroup",
    foreign_key: :event_id,
    before_add: :prevent_association_changes_in_weak_validation_state,
    before_remove: :prevent_association_changes_in_weak_validation_state,
    after_add: :track_association_addition,
    after_remove: :track_association_removal

  has_and_belongs_to_many :technical_requirements,
    join_table: :events_technical_requirements,
    class_name: "Event::TechnicalRequirement",
    foreign_key: :event_id,
    before_add: :prevent_association_changes_in_weak_validation_state,
    before_remove: :prevent_association_changes_in_weak_validation_state,
    after_add: :track_association_addition,
    after_remove: :track_association_removal

  has_and_belongs_to_many :traits,
    join_table: :events_traits,
    class_name: "Event::Trait",
    foreign_key: :event_id,
    after_add: :track_association_addition,
    after_remove: :track_association_removal

  translates :alternative_route, :additional_info, :price_description

  ### VALIDATIONS

  before_save :prevent_changes_in_weak_validation_state, unless: :weak_validation_state?
  validates :state, inclusion: possible_states
  validates :disciplines, :target_groups, :technical_requirements,
    :fitness_requirement, :season, presence: {unless: :weak_validation_state?}

  validates :duration_h, :duration_m, numericality: {
    greater_than_or_equal_to: 0,
    less_than: 100
  }, allow_nil: true

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

  def track_association_addition(record)
    track_association_change(record, :create)
  end

  # We use removed as a custom event for paper trail versions, since destroy would be wrong
  # The associated records are not destroyed, only the association to them is destroyed
  # all the records still exist, we don't have to reify them or anything to display in log
  def track_association_removal(record)
    track_association_change(record, :removed)
  end

  def track_association_change(record, event)
    ids_method_name = "#{record.model_name.element}_ids"
    object_changes = {ids_method_name => [[], send(ids_method_name)]}
    PaperTrail::Version.create!(main: self, item: record, event: event, object: record.to_yaml,
      object_changes: object_changes.to_yaml)
  end
end
