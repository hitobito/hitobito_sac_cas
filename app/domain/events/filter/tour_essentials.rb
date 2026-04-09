# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Events::Filter
  class TourEssentials < Base
    self.permitted_args = [
      :discipline_id,
      :target_group_id,
      :fitness_requirement_id,
      :technical_requirement_id,
      :trait_id
    ]

    def initialize(*)
      super
      @args = @args.transform_values { |v| normalize_ids(v) }.compact_blank
    end

    def apply(scope)
      scope = filter_disciplines(scope)
      scope = filter_target_groups(scope)
      scope = filter_fitness_requirements(scope)
      scope = filter_technical_requirements(scope)
      filter_traits(scope)
    end

    private

    def filter_disciplines(scope)
      filter_essential_or_parent(scope, :discipline_id, :disciplines)
    end

    def filter_target_groups(scope)
      filter_essential_or_parent(scope, :target_group_id, :target_groups)
    end

    def filter_fitness_requirements(scope)
      ids = args[:fitness_requirement_id]
      return scope if ids.blank?

      scope.where(fitness_requirement_id: ids)
    end

    def filter_technical_requirements(scope)
      filter_essential_or_parent(scope, :technical_requirement_id, :technical_requirements)
    end

    def filter_traits(scope)
      filter_essential_or_parent(scope, :trait_id, :traits)
    end

    def filter_essential_or_parent(scope, key, table)
      ids = args[key]
      return scope if ids.blank?

      scope
        .joins("INNER JOIN events_#{table} ON events.id = events_#{table}.event_id")
        .joins("INNER JOIN event_#{table} ON events_#{table}.#{key} = event_#{table}.id")
        .where("event_#{table}.id IN (:ids) OR event_#{table}.parent_id IN (:ids)", ids: ids)
    end

    def normalize_ids(value)
      Array(value).compact_blank.map(&:to_i)
    end
  end
end
