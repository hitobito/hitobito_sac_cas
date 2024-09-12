# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class QualificationsImporter
    REPORT_HEADERS = [
      :navision_id,
      :hitobito_person,
      :navision_qualification_active,
      :navision_start_at,
      :navision_finish_at,
      :navision_qualification_kind,
      :errors
    ]

    def initialize(output: $stdout)
      @output = output
      @source_file = CsvSource.new(:NAV3)
      @csv_report = CsvReport.new(:"8_qualifications", REPORT_HEADERS)
    end

    def create
      data = @source_file.rows
      data.each do |row|
        process_row(row)
      end
      @csv_report.finalize(output: @output)
    end

    private

    def process_row(row)
      @output.print("#{row[:navision_id]} (#{row[:qualification_kind]}):")
      entry = QualificationEntry.new(row)
      @output.print(entry.valid? ? " ✅\n" : " ❌ #{entry.error_messages}\n")
      if entry.valid?
        entry.import!
      else
        @csv_report.add_row({
          navision_id: row[:navision_id],
          hitobito_person: entry.person&.to_s,
          navision_qualification_active: row[:start_at],
          navision_start_at: row[:start_at],
          navision_finish_at: row[:finish_at],
          navision_qualification_kind: row[:qualification_kind],
          errors: entry.error_messages
        })
      end
    end
  end
end
