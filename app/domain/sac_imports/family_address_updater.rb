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

    def initialize(output: $stdout)
      @csv_report = CsvReport.new(
        :update_sac_familiy_address,
        REPORT_HEADERS,
        output:
      )
    end

    def update
      progress = Progress.new(family_main_people.size, title: "Family Address Updater", output: @output)

      with_paper_trail do
        family_main_people.each do |main_person|
          progress.step
          preferred_person = get_preferred_household_person_with_valid_address(main_person)
          next if preferred_person.nil?

          preferred_person.household_people.each do |household_person|
            if household_person.address_attrs != preferred_person.address_attrs
              household_person.update!(preferred_person.address_attrs)
            end
          end
        end
      end
    end

    private

    def with_paper_trail
      paper_trail_was_enabled = PaperTrail.enabled?
      PaperTrail.enabled = true # enable versioning for address updates
      yield
    ensure
      PaperTrail.enabled = paper_trail_was_enabled
    end

    def get_preferred_household_person_with_valid_address(main_person)
      if !address_ok?(main_person)
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

    def address_ok?(person)
      person.town.present? && person.zip_code.present? &&
        (person.street.present? || person.postbox.present?)
    end

    def oldest_family_member_with_valid_address(main_person)
      main_person.household_people.select { |person| address_ok?(person) }.min_by(&:birthday)
    end

    def family_main_people = @family_main_people ||= Person.where(sac_family_main_person: true)

    def add_report_row(navision_id, message)
      @csv_report.add_row({
        navision_id: navision_id,
        message: message
      })
    end
  end
end
