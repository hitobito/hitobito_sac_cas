# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav18EventsImporter
    include LogCounts

    REPORT_HEADERS = [
      :number,
      :name_de,
      :status,
      :errors
    ]

    def initialize(output: $stdout, import_spec_fixture: false)
      @output = output
      # spec fixture includes all sections and it's public data
      @import_spec_fixture = import_spec_fixture
      @source_file = source_file
      @csv_report = SacImports::CsvReport.new("nav18-events", REPORT_HEADERS, output:)
    end

    def create
      @csv_report.log("The file contains #{@source_file.lines_count} rows.")
      progress = Progress.new(@source_file.lines_count, title: "NAV18 Events")

      log_counts_delta(@csv_report, Event.unscoped) do
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
        CsvSource.new(:NAV18, source_dir: spec_fixture_dir)
      else
        CsvSource.new(:NAV18)
      end
    end

    def spec_fixture_dir
      Pathname.new(HitobitoSacCas::Wagon.root.join("spec", "fixtures", "files", "sac_imports_src"))
    end

    def process_row(row)
      entry = Events::EventEntry.new(row, associations)
      entry.import! if entry.valid?
      report_warnings(entry)
      report_errors(entry)
    end

    def report_errors(entry)
      return if entry.errors.blank?

      @output.puts("#{entry.row.name_de} (#{entry.row.number}): ❌ #{entry.error_messages}")
      @csv_report.add_row(
        number: entry.row.number,
        name_de: entry.row.name_de,
        status: "error",
        errors: entry.error_messages
      )
    end

    def report_warnings(entry)
      return if entry.warnings.blank?

      @csv_report.add_row(
        number: entry.row.number,
        name_de: entry.row.name_de,
        status: "warning",
        errors: entry.warnings.join(", ")
      )
    end

    def associations
      @associations ||= {
        kinds: Event::Kind::Translation.where(locale: :de).pluck(:short_name, :event_kind_id).to_h,
        cost_centers: CostCenter.pluck(:code, :id).to_h,
        cost_units: CostUnit.pluck(:code, :id).to_h,
        groups: {root: Group.root}
      }
    end
  end
end
