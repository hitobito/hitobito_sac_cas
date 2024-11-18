# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class FamilyAddressUpdater
    def update
      family_main_people.each do |main_person|        
        main_person.household_people.each do |household_person|
          if household_person.address != main_person.address
            household_person.update!(street: main_person.street)
          end
        end
      end
    end

    private

    def family_main_people = Person.where(sac_family_main_person: true)
  end
end
