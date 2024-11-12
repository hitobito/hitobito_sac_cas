# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav1PeopleImporter
    include LogCounts

    REPORT_HEADERS = [
      :navision_membership_number,
      :navision_name,
      :status,
      :warnings,
      :errors
    ]

    def initialize(output: $stdout)
      PaperTrail.enabled = false # disable versioning for imports
      truemail_with_regex
      @output = output
      @source_file = CsvSource.new(:NAV1)
      @csv_report = CsvReport.new(:"nav1-1_people", REPORT_HEADERS, output:)
      @existing_emails = load_existing_emails
    end

    def create(start_at_navision_id: nil)
      data = @source_file.rows
      @csv_report.log("The file contains #{data.size} rows.")
      progress = Progress.new(data.size, title: "NAV1 People Import", output: @output)

      if start_at_navision_id.present?
        start_from_row = data.find { |row| row.navision_id == start_at_navision_id }
        data = data[data.index(start_from_row)..]
        @output.print("Starting import from row with navision_id #{start_at_navision_id} (#{start_from_row.last_name} #{start_from_row.first_name})\n")
      end

      log_counts_delta(@csv_report,
        Person.unscoped,
        AdditionalEmail.where(contactable_type: Person.sti_name)) do
        Parallel.map(data, in_threads: Etc.nprocessors) do |row|
          # data.each do |row|
          progress.step
          process_row(row)
        end
      end

      @csv_report.finalize
    end

    private

    def load_existing_emails
      Concurrent::Set.new(Person.select("lower(email) as email").distinct.pluck(:email))
    end

    def truemail_with_regex
      Truemail.configuration.default_validation_type = :regex
    end

    def target_group
      @target_group ||= Group::ExterneKontakte.find_or_create_by!(
        name: "Navision Import",
        parent_id: Group::SacCas.first!.id
      )
    end

    def process_row(row)
      entry = People::PersonEntry.new(row, target_group, @existing_emails)
      name = "#{row.first_name} #{row.last_name}"
      if entry.valid?
        entry.import!
        if entry.warning
          @csv_report.add_row({
            navision_membership_number: row.navision_id,
            navision_name: name,
            warnings: entry.warning,
            status: "warning"
          })
        end
      else
        @output.print("#{row.navision_id} (#{name}): ❌ #{entry.errors}\n")
        @csv_report.add_row({
          navision_membership_number: row.navision_id,
          navision_name: name,
          errors: entry.errors,
          status: "error"
        })
      end
    end
  end
end
