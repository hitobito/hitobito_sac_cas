# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class FamilyAddressUpdater

    REPORT_HEADERS = [
      :navision_id,
      :message
    ].freeze

    def initialize
      @csv_report = CsvReport.new(:"update_sac_familiy_address", REPORT_HEADERS)
    end

    def update
      family_main_people.each do |main_person|
        preferred_person = get_preferred_household_person_with_valid_address(main_person)
        next if preferred_person.nil?

        preferred_person.household_people.each do |household_person|
          if household_person.address_attrs != preferred_person.address_attrs
            household_person.update!(preferred_person.address_attrs)
          end
        end
      end
    end

    private

    def get_preferred_household_person_with_valid_address(main_person)
      if [main_person.street, main_person.housenumber, main_person.zip_code, main_person.town].any?(&:nil?)
        if oldest_family_member_with_valid_address(main_person).nil?
          add_report_row(main_person.id, "ERROR: Familienhauptperson hat keine gültige Adresse und keine Familienmitglieder mit gültigen Adressen")
          nil
        else
          add_report_row(main_person.id, "WARNING: Familienhauptperson hat keine gültige Adresse")
          oldest_family_member_with_valid_address(main_person)
        end
      else
        main_person
      end
    end

    def oldest_family_member_with_valid_address(main_person)
      main_person.household_people.select { |person| person.street && person.housenumber && person.zip_code && person.town }.min_by(&:birthday)
    end

    def family_main_people = Person.where(sac_family_main_person: true)

    def add_report_row(navision_id, message)
      @csv_report.add_row({
        navision_id: navision_id,
        message: message
      })
    end
  end
end
