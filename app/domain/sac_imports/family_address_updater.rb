# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class FamilyAddressUpdater
    def update
      family_main_people.each do |main_person|
        if [main_person.street, main_person.housenumber, main_person.zip_code, main_person.town].any?(&:nil?)
          warn("Main person does not have a valid address: #{main_person.id}")
          main_person = main_person.household_people
            .select { |person| person.street && person.housenumber && person.zip_code && person.town }
            .min_by(&:birthday)
        end

        main_person.household_people.each do |household_person|
          if household_person.address_attrs != main_person.address_attrs
            household_person.update!(main_person.address_attrs)
          end
        end
      end
    end

    private

    def family_main_people = Person.where(sac_family_main_person: true)

    def warn(message)
      @warning = [@warning, message].compact.join(" / ")
    end
  end
end
