# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::EventResource
  extend ActiveSupport::Concern

  included do
    self.polymorphic = [
      "EventResource",
      "Event::CourseResource",
      "Event::TourResource"
    ]

    filter :level_id, :integer, only: [:eq, :not_eq] do
      eq { |scope, level_ids|
        scope.select("events.*").joins(:kind).where(kind: {level_id: level_ids})
      }
      not_eq { |scope, level_ids|
        scope.select("events.*").joins(:kind).where.not(kind: {level_id: level_ids})
      }
    end

    filter :activity_id, :integer, only: [:eq] do
      eq { |scope, ids| scope.where(id: tours_with(:activities, ids)) }
    end

    filter :target_group_id, :integer, only: [:eq] do
      eq { |scope, ids| scope.where(id: tours_with(:target_groups, ids)) }
    end

    filter :technical_requirement_id, :integer, only: [:eq] do
      eq { |scope, ids| scope.where(id: tours_with(:technical_requirements, ids)) }
    end

    filter :trait_id, :integer, only: [:eq] do
      eq { |scope, ids| scope.where(id: tours_with(:traits, ids)) }
    end

    filter :fitness_requirement_id, :integer, only: [:eq] do
      eq { |scope, ids| scope.where(fitness_requirement_id: ids) }
    end
  end

  private

  # The filters run on the polymorphic Event scope, which does not know the Event::Tour
  # associations, hence the matching tours are looked up in a subquery.
  # Filtering by a main entry matches the tours assigned to one of its children as well.
  def tours_with(association, ids)
    model = Event::Tour.reflect_on_association(association).klass
    matching = model.where(id: ids).or(model.where(parent_id: ids)).select(:id)
    Event::Tour.joins(association).where(model.table_name => {id: matching}).select(:id)
  end
end
