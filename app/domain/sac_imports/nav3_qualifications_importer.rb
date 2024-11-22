# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav3QualificationsImporter
    include LogCounts

    REPORT_HEADERS = [
      :navision_id,
      :hitobito_person,
      :navision_qualification_active,
      :navision_start_at,
      :navision_finish_at,
      :navision_qualification_kind,
      :status,
      :warnings,
      :errors
    ]

    def initialize(output: $stdout)
      @output = output
      @source_file = CsvSource.new(:NAV3)
      @csv_report = CsvReport.new(:nav3_qualifications, REPORT_HEADERS, output:)
    end

    def create
      data = @source_file.rows

      @csv_report.log("The file contains #{data.size} rows.")
      progress = Progress.new(data.size, title: "NAV3 Qualifications")

      log_counts_delta(@csv_report, Qualification) do
        data.each do |row|
          progress.step
          process_row(row)
        end
      end
      @csv_report.finalize
    end

    private

    def process_row(row)
      # @output.print("#{row.navision_id} (#{row.qualification_kind}):")
      entry = QualificationEntry.new(row)
      # @output.print(entry.valid? ? " ✅\n" : " ❌ #{entry.error_messages}\n")
      if entry.valid?
        entry.import!
        if entry.warning
          @csv_report.add_row({
            navision_id: row.navision_id,
            hitobito_person: entry.person&.to_s,
            navision_qualification_active: row.start_at,
            navision_start_at: row.start_at,
            navision_finish_at: row.finish_at,
            navision_qualification_kind: row.qualification_kind,
            status: "warning",
            warnings: entry.warning
          })
        end
      else
        @output.puts("#{row.navision_id} (#{row.qualification_kind}): ❌ #{entry.error_messages}")
        @csv_report.add_row({
          navision_id: row.navision_id,
          hitobito_person: entry.person&.to_s,
          navision_qualification_active: row.start_at,
          navision_start_at: row.start_at,
          navision_finish_at: row.finish_at,
          navision_qualification_kind: row.qualification_kind,
          status: "error",
          errors: entry.error_messages
        })
      end
    end
  end
end
