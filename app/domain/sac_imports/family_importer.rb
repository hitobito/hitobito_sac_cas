# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class FamilyImporter
    REPORT_HEADERS = [
      :navision_id,
      :hitobito_person,
      :household_key,
      :errors
    ]
    class ImportError < StandardError; end

    attr_reader :output, :source_file, :csv_report

    def initialize(output: $stdout)
      @output = output
      @source_file = CsvSource.new(:NAV1)
      @csv_report = CsvReport.new(:"nav1-2_sac_families", REPORT_HEADERS)
    end

    def create
      reset_all_household_keys!
      Role.where(type: "Group::SektionsMitglieder::Mitglied", beitragskategorie: :family).includes(:person).find_each do |role|
        process_person(role.person)
      end
      sanity_check_families
      @csv_report.finalize(output: @output)
    end

    private

    def rows
      @rows ||= @source_file.rows
    end

    def reset_all_household_keys!
      person_ids = rows.pluck(:navision_id)
      Person.where(id: person_ids).update_all(household_key: nil)
    end

    def person_id_to_household_key(person_id)
      @person_id_to_household_key_map ||= rows.filter { |p| !p[:family].nil? }.to_h { |p| [p[:navision_id], p[:family]] }
      @person_id_to_household_key_map[person_id.to_s]
    end

    def process_person(person)
      household_key = person_id_to_household_key(person.id)
      @output.print("#{person.id} (#{person}):")
      assign_household(person, household_key)
      @output.print(" ✅\n")
    rescue ImportError, ActiveRecord::RecordInvalid => e
      @output.print(" ❌ #{e.message}\n")
      @csv_report.add_row({
        navision_id: person.id,
        hitobito_person: person.to_s,
        household_key: household_key,
        errors: e.message
      })
    end

    def assign_household(person, household_key)
      raise ImportError, "No household_key found in NAV1 data" if household_key.blank?
      return if household_key == person.household_key # already assigned

      if (other_person = ::Person.find_by(household_key: household_key))
        # Household key exists already, assign person to existing household
        household = Household.new(other_person, maintain_sac_family: false)
        household.add(person)
        household.save!(context: :import)
      else
        # Household key does not exist yet, save it on the person
        person.update_columns(household_key: household_key)
      end
    end

    def sanity_check_families
      Person.group(:household_key).having("COUNT(*) = 1").pluck(:household_key).each do |household_key|
        person = Person.find_by(household_key: household_key)
        @csv_report.add_row({
          navision_id: person.id,
          hitobito_person: person.to_s,
          household_key: household_key,
          errors: "Only one person in household"
        })
      end
    end
  end
end
