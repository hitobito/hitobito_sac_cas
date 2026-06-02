# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics
  class Section
    AGE_GROUPS = [
      6..17,
      18..22,
      23..35,
      36..50,
      51..60,
      61..
    ]
    class_attribute :groupings

    attr_reader :group, :range, :relevant_role_types

    def initialize(range, group = nil, relevant_role_types: nil)
      @range = range
      @group = group
      @relevant_role_types = relevant_role_types
    end

    def title
      self.class.name.demodulize.underscore
    end

    def title_options
      {from: I18n.l(range.begin), to: I18n.l(range.end)}
    end

    def total
      scope.count
    end

    def counts(grouping)
      send(:"count_by_#{grouping}")
    end

    private

    def scope
      # implement in subclass
    end

    def count_by_gender
      count_by_group(:gender, Person::GENDERS + [nil])
    end

    def count_by_language
      count_by_group(:language, Person::LANGUAGES.keys.map(&:to_s))
    end

    def count_by_age
      counts = scope.group(age_sql).count
      AGE_GROUPS.each_with_object({}) do |range, hash|
        label = range.end ? "#{range.begin}-#{range.end}" : "#{range.begin}+"
        hash[label] = counts.select { |k, v| range.include?(k) }.values.sum
      end
    end

    def count_by_beitragskategorie
      count_by_group(
        BeitragskategorieValue.new(reference_date).sql,
        BeitragskategorieValue::VALUES
      )
    end

    def count_by_group(column, values)
      counts = scope.group(column).count
      values.each_with_object({}) do |value, hash|
        hash[value] = counts[value] || 0
      end
    end

    def age_sql
      Person.sanitize_sql_array(["DATE_PART('YEAR', AGE(?, birthday))", reference_date])
    end

    def reference_date
      range.end
    end
  end
end
