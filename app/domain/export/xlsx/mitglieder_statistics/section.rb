# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics::Section
  AGE_GROUPS = [
    6..17,
    18..22,
    23..35,
    36..50,
    51..60,
    61..
  ]

  BEITRAGSKATEGORIEN = %w[
    adult
    family_main
    family_adult
    family_child
    youth
  ]

  class_attribute :groupings

  attr_reader :group, :range

  def initialize(group, range)
    @group = group
    @range = range
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
    count_by_group(beitragskategorie_sql, BEITRAGSKATEGORIEN)
  end

  def count_by_group(column, values)
    counts = scope.group(column).count
    values.each_with_object({}) do |value, hash|
      hash[value] = counts[value] || 0
    end
  end

  def beitragskategorie_sql
    <<-SQL.squish
      CASE WHEN beitragskategorie = 'adult' THEN 'adult'
      WHEN beitragskategorie = 'family' AND sac_family_main_person THEN 'family_main'
      WHEN beitragskategorie = 'family' AND #{age_sql} >= #{adult_age} THEN 'family_adult'
      WHEN beitragskategorie = 'family' AND #{age_sql} <= #{child_age} THEN 'family_child'
      WHEN beitragskategorie = 'youth' THEN 'youth'
      END
    SQL
  end

  def adult_age
    SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT.first
  end

  def child_age
    # set + 1 to still count children in the year they are turning 18
    SacCas::Beitragskategorie::Calculator::AGE_RANGE_MINOR_FAMILY_MEMBER.last + 1
  end

  def age_sql
    Person.sanitize_sql_array(["DATE_PART('YEAR', AGE(?, birthday))", date])
  end

  def date
    range.end
  end
end
