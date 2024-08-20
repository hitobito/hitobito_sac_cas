# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class PeopleImporter
    REPORT_HEADERS = [
      :navision_membership_number,
      :navision_name,
      :errors
    ]

    def initialize(output: $stdout)
      @output = output
      @source_file = CsvSource.new(:NAV1)
      @csv_report = CsvReport.new(:"1_people", REPORT_HEADERS)
    end

    def create
      data = @source_file.rows
      data.each do |row|
        process_row(row)
      end
      @csv_report.finalize(output: @output)
    end

    def target_group
      @target_group ||= Group::ExterneKontakte.find_or_create_by!(
        name: "Navision Import",
        parent_id: Group::SacCas.first!.id
      )
    end

    def process_row(row)
      @output.print("#{row[:navision_id]} (#{row[:navision_name]}):\n")
      entry = PersonEntry.new(row, target_group)
      @output.print("-> #{entry.errors.full_messages.join(", ")}\n")
      # entry.import!
    end
  end
end
