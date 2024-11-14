# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav6SectionsImporter
    include LogCounts

    REPORT_HEADERS = [
      :id,
      :parent_id,
      :section_name,
      :status,
      :errors
    ]

    def initialize(output: $stdout, import_spec_fixture: false)
      @output = output
      # spec fixture includes all sections and it's public data
      @import_spec_fixture = import_spec_fixture
      @source_file = source_file
      @csv_report = SacImports::CsvReport.new("nav6-sections", REPORT_HEADERS, output:)
    end

    def create
      set_pk_sequence

      @csv_report.log("The file contains #{data.size} rows.")
      progress = Progress.new(data.size, title: "NAV6 Sections")

      log_counts_delta(@csv_report, Group.unscoped) do
        data.each do |row|
          progress.step
          process_row(row)
        end
      end

      @csv_report.finalize
    end

    private

    # We use the provided navision_id as primary key for the groups.
    # But Sektion and Ortsgruppe create have default child groups, so we must set the primary key
    # sequence to a higher value than the highest group navision_id to avoid collisions.
    def set_pk_sequence
      return if Group.maximum(:id).to_i > 6000

      ActiveRecord::Base.connection.set_pk_sequence!(:groups, 6000)
    end

    def source_file
      if @import_spec_fixture
        CsvSource.new(:NAV6, source_dir: spec_fixture_dir)
      else
        CsvSource.new(:NAV6)
      end
    end

    def spec_fixture_dir
      Pathname.new(HitobitoSacCas::Wagon.root.join("spec", "fixtures", "files", "sac_imports_src"))
    end

    def data
      @data ||= @source_file.rows.sort_by { |row| row.navision_id }
    end

    def process_row(row)
      entry = SacSections::GroupEntry.new(row)
      entry.import! if entry.valid?
      report(entry) if entry.errors.present?
    end

    def report(entry)
      @output.puts("#{row.section_name}: ❌ #{entry.errors}\n") if entry.errors.present?
      @csv_report.add_row(
        id: entry.group.id,
        parent_id: entry.group.parent_id,
        group_name: entry.group.name,
        status: entry.errors.blank? ? "success" : "error",
        errors: entry.errors
      )
    end
  end
end
