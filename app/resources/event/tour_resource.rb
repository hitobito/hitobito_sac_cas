# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::TourResource < EventResource
  with_options writable: false, filterable: false, sortable: false do
    attribute :state, :string, filterable: true
    attribute :applicant_count, :integer
    attribute :participant_count, :integer
    attribute :minimum_participants, :integer
    attribute :teamer_count, :integer
    attribute :summit, :string
    attribute :ascent, :integer
    attribute :descent, :integer
    attribute :season, :string
    attribute :minimum_age, :integer
    attribute :maximum_age, :integer
    attribute :tourenportal_link, :string
    attribute :subito, :boolean
  end

  has_many :leaders, resource: Person::NameResource, writable: false,
    foreign_key: :leads_course_id

  def base_scope
    Event::Tour.all.accessible_by(index_ability).includes(:groups, :translations).list
  end
end
