# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics
  class BeitragskategorieValue
    VALUES = %w[
      adult
      family_main
      family_adult
      family_child
      youth
    ]

    attr_reader :date

    def initialize(date)
      @date = date
    end

    def sql
      <<-SQL.squish
      CASE WHEN beitragskategorie = 'adult' THEN 'adult'
      WHEN beitragskategorie = 'family' AND sac_family_main_person THEN 'family_main'
      WHEN beitragskategorie = 'family' AND #{age_sql} >= #{adult_age} THEN 'family_adult'
      WHEN beitragskategorie = 'family' AND #{age_sql} <= #{child_age} THEN 'family_child'
      WHEN beitragskategorie = 'youth' THEN 'youth'
      END
      SQL
    end

    private

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
  end
end
