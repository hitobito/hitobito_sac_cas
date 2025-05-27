# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav2a3FamilyImporter
    include LogCounts

    REPORT_HEADERS = [
      :navision_id,
      :hitobito_person,
      :household_key,
      :errors
    ]
    class ImportError < StandardError; end

    attr_reader :output, :source_file, :csv_report

    def initialize(output: $stdout)
      # PaperTrail.enabled = false # disable versioning for imports
      @output = output
      @source_file = CsvSource.new(:NAV1)
      @csv_report = CsvReport.new(:"nav2a3-families", REPORT_HEADERS, output:)
    end

    def create
      progress = Progress.new(memberships_by_family.size, title: "NAV2a3 Family Import")

      log_counts_delta(@csv_report,
        "Households" => Person.unscoped.select(:household_key).distinct,
        "Household People" => Person.unscoped.where.not(household_key: nil),
        "PeopleManager" => PeopleManager.unscoped) do
        reset_all_households!
        memberships_by_family.sort.each do |family_id, memberships|
          progress.step
          next log_missing_family_id(memberships) if family_id.blank?
          # @output.puts "Processing family #{family_id}"

          housemates = memberships.map(&:person)
          Person.unscoped.where(id: housemates.map(&:id)).update_all(household_key: family_id)

          create_missing_people_managers(memberships.map(&:person))
        end
        sanity_check_families
        @csv_report.finalize
      end
    end

    private

    def log_missing_family_id(memberships)
      memberships.each do |role|
        @csv_report.add_row({
          navision_id: role.person.id,
          hitobito_person: role.person.to_s,
          household_key: nil,
          errors: "No family id set on role #{role.id}"
        })
      end
    end

    def memberships_by_family
      # relevant sind nur Familienmitglieder mit ungekündigter Mitgliedschaft
      # die bis Ende 2024 aktiv sind
      @memberships_by_family = Group::SektionsMitglieder::Mitglied
        .active(Date.new(2024, 12, 31))
        .where(terminated: false)
        .where(beitragskategorie: :family).group_by(&:family_id)
    end

    def rows
      @rows ||= @source_file.rows
    end

    def reset_all_households!
      deleted_pm_count = PeopleManager.delete_all
      @csv_report.log("Prepare: Deleted #{deleted_pm_count} people managers")
      cleared_household_keys_count = Person.where.not(household_key: nil)
        .update_all(household_key: nil)
      @csv_report.log("Prepare: Cleared #{cleared_household_keys_count} household keys")
    end

    def create_missing_people_managers(people)
      adults = people.select { calculator(_1).adult? }
      children = people.select { calculator(_1).child? }

      adults.product(children).each do |adult, child|
        PeopleManager.create!(manager: adult, managed: child)
      end
    end

    def calculator(person) = SacCas::Beitragskategorie::Calculator.new(person)

    def sanity_check_families
      Person.group(:household_key).having("COUNT(*) = 1").pluck(:household_key).each do |household_key|
        Person.where(household_key: household_key).find_each do |person|
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
end
