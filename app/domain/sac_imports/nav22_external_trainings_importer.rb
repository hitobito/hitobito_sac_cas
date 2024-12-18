# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav22ExternalTrainingsImporter
    include LogCounts

    REPORT_HEADERS = [
      :person_id,
      :start_at,
      :status,
      :errors
    ]

    def initialize(output: $stdout, import_spec_fixture: false)
      @output = output
      # spec fixture includes all sections and it's public data
      @import_spec_fixture = import_spec_fixture
      @source_file = source_file
      @csv_report = SacImports::CsvReport.new("nav22-external-trainings", REPORT_HEADERS, output:)
    end

    def create
      ExternalTraining.skip_callback(:save, :after, :issue_qualifications)

      @csv_report.log("The file contains #{@source_file.lines_count} rows.")
      progress = Progress.new(@source_file.lines_count, title: "NAV22 External Trainings")

      log_counts_delta(@csv_report, ExternalTraining.unscoped) do
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
        CsvSource.new(:NAV22, source_dir: spec_fixture_dir)
      else
        CsvSource.new(:NAV22)
      end
    end

    def spec_fixture_dir
      Pathname.new(HitobitoSacCas::Wagon.root.join("spec", "fixtures", "files", "sac_imports_src"))
    end

    def process_row(row)
      entry = Events::ExternalTrainingEntry.new(row, associations)
      entry.import! if entry.valid?
      report_warnings(entry)
      report_errors(entry)
    end

    def report_errors(entry)
      return if entry.errors.blank?

      @output.puts("#{entry.row.person_id} - #{entry.row.start_at}: ❌ #{entry.error_messages}")
      @csv_report.add_row(
        person_id: entry.row.person_id,
        start_at: entry.row.start_at,
        status: "error",
        errors: entry.error_messages
      )
    end

    def report_warnings(entry)
      return if entry.warnings.blank?

      @csv_report.add_row(
        person_id: entry.row.person_id,
        start_at: entry.row.start_at,
        status: "warning",
        errors: entry.warnings.join(", ")
      )
    end

    def associations
      @associations ||= {
        event_kinds: Event::Kind::Translation.where(locale: :de).pluck(:short_name, :event_kind_id).to_h
      }
    end
  end
end
