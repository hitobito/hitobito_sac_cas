# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Beitragskategorie
  class Calculator < Base

    def initialize(person)
      @person = person
    end

    def calculate
      return :familie if family_member?

      case age
      when 22..199
        :einzel
      when 6..21
        :jugend
      else
        nil
      end
    end

    private

    def age
      @person.years
    end

    def family_member?
      return false if (17..21).include?(age)

      @person.household_key?
    end
  end
end
