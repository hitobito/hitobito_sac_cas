# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Beitragskategorie
  class Calculator

    BEITRAGSKATEGORIEN = %w(einzel jugend familie).freeze
    AGE_ADULT = 22..199
    AGE_YOUTH = 6...AGE_ADULT.begin
    AGE_MINOR_FAMILY_MEMBER = AGE_YOUTH.begin..16

    CATEGORY_ADULT = :einzel
    CATEGORY_YOUTH = :jugend
    CATEGORY_FAMILY = :familie

    def initialize(person)
      @person = person
    end

    def calculate
      return CATEGORY_FAMILY if family_member?

      case age
      when AGE_ADULT
        CATEGORY_ADULT
      when AGE_YOUTH
        CATEGORY_YOUTH
      end
    end

    private

    def age
      @person.years
    end

    def family_member?
      return false unless AGE_ADULT.include?(age) || AGE_MINOR_FAMILY_MEMBER.include?(age)

      @person.household_key?
    end
  end
end
