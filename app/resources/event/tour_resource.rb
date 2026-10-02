# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::TourResource < EventResource
  self.readable_class = EventResource.readable_class

  with_options writable: false, filterable: false, sortable: false do
    attribute :state, :string, filterable: true
    attribute :season, :string, filterable: true
    attribute :subito, :boolean, filterable: true
    attribute :applicant_count, :integer
    attribute :participant_count, :integer
    attribute :teamer_count, :integer
    attribute :display_booking_info, :boolean
    attribute :minimum_participants, :integer
    attribute :summit, :string
    attribute :ascent, :integer
    attribute :descent, :integer
    attribute :duration, :integer
    attribute :maps, :string
    attribute :alternative_route, :string
    attribute :additional_info, :string
    attribute :tourenportal_link, :string
    attribute :price_member, :float
    attribute :price_regular, :float
    attribute :price_special, :float
    attribute :price_description, :string
    attribute :special_may_apply, :boolean
    attribute :member_may_apply, :boolean
    attribute :regular_may_apply, :boolean
    attribute :minimum_age, :integer
    attribute :maximum_age, :integer
  end

  has_many :leaders, resource: Person::NameResource, writable: false,
    foreign_key: :leads_course_id

  has_many :activities, resource: Event::ActivityResource
  has_many :target_groups, resource: Event::TargetGroupResource
  has_many :technical_requirements, resource: Event::TechnicalRequirementResource
  has_many :traits, resource: Event::TraitResource

  belongs_to :fitness_requirement, resource: Event::FitnessRequirementResource

  def base_scope
    super.includes(:groups, :translations).list
  end
end
