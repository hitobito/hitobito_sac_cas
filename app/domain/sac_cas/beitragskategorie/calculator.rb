# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Beitragskategorie
  class Calculator

    BEITRAGSKATEGORIEN = [CATEGORY_ADULT, CATEGORY_YOUTH, CATEGORY_FAMILY].freeze
    AGE_RANGE_ADULT = 22..199
    AGE_RANGE_MINOR_FAMILY_MEMBER = 6..17
    AGE_RANGE_YOUTH = AGE_RANGE_MINOR_FAMILY_MEMBER.begin...AGE_RANGE_ADULT.begin

    CATEGORY_ADULT = :adult
    CATEGORY_YOUTH = :youth
    CATEGORY_FAMILY = :familie
    
    def initialize(person, reference_date: Time.zone.today)
      @person = person
      @reference_date = reference_date
    end

    def calculate
      return CATEGORY_FAMILY if family_member?

      case age
      when AGE_RANGE_ADULT
        CATEGORY_ADULT
      when AGE_RANGE_YOUTH
        CATEGORY_YOUTH
      end
    end

    def adult?
      AGE_RANGE_ADULT.cover?(age)
    end

    # Attention: overlap with child?, make sure to use it correctly depending on context
    def youth?
      AGE_RANGE_YOUTH.cover?(age)
    end

    # Attention: overlap with youth?, make sure to use it correctly depending on context
    def child?
      AGE_RANGE_MINOR_FAMILY_MEMBER.cover?(age)
    end

    def pre_school_child?
      (0..AGE_RANGE_MINOR_FAMILY_MEMBER.begin).cover?(age)
    end

    def family_age?
      adult? || child?
    end

    private

    def age
      @person.years(@reference_date)
    end

    def family_member?
      return false unless AGE_RANGE_ADULT.cover?(age) || AGE_RANGE_MINOR_FAMILY_MEMBER.cover?(age)

      @person.household_key?
    end

  end
end
