# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav21EventParticipationsImporter
    include LogCounts

    REPORT_HEADERS = [
      :event_number,
      :person_id,
      :status,
      :errors
    ]

    def initialize(output: $stdout, import_spec_fixture: false)
      @output = output
      # spec fixture includes all sections and it's public data
      @import_spec_fixture = import_spec_fixture
      @source_file = source_file
      @csv_report = SacImports::CsvReport.new("nav21-event-participations", REPORT_HEADERS, output:)
    end

    def create
      @csv_report.log("The file contains #{@source_file.lines_count} rows.")
      progress = Progress.new(@source_file.lines_count, title: "NAV21 Event Participations")

      log_counts_delta(@csv_report, Event::Participation.unscoped) do
        @source_file.rows do |row|
          progress.step
          process_row(row)
        end
      end

      @csv_report.finalize
    end

    private

    def source_file
      if @import_spec_fixture
        CsvSource.new(:NAV21, source_dir: spec_fixture_dir)
      else
        CsvSource.new(:NAV21)
      end
    end

    def spec_fixture_dir
      Pathname.new(HitobitoSacCas::Wagon.root.join("spec", "fixtures", "files", "sac_imports_src"))
    end

    def process_row(row)
      entry = Events::ParticipationEntry.new(row)
      entry.import! if entry.valid?
      report_warnings(entry)
      report_errors(entry)
    end

    def report_errors(entry)
      return if entry.errors.blank?

      @output.puts("#{entry.row.event_number} - #{entry.row.person_id}: ❌ #{entry.error_messages}")
      @csv_report.add_row(
        event_number: entry.row.event_number,
        person_id: entry.row.person_id,
        status: "error",
        errors: entry.error_messages
      )
    end

    def report_warnings(entry)
      return if entry.warnings.blank?

      @csv_report.add_row(
        event_number: entry.row.event_number,
        person_id: entry.row.person_id,
        status: "warning",
        errors: entry.warnings.join(", ")
      )
    end
  end
end
