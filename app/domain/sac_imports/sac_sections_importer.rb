# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class SacSectionsImporter
    def initialize(output: $stdout, import_spec_fixture: false)
      @output = output
      # spec fixture includes all sections and it's public data
      @import_spec_fixture = import_spec_fixture
      @source_file = source_file
    end

    def create
      section_rows.each do |row|
        process_row(row)
      end

      # ortsgruppe needs parent section to exist
      ortsgruppen_rows.each do |row|
        process_row(row)
      end
    end

    private

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
      @data ||= @source_file.rows
    end

    def section_rows
      data.select do |row|
        row[:level_3_id].blank?
      end
    end

    def ortsgruppen_rows
      data.select do |row|
        row[:level_3_id].present?
      end
    end

    def process_row(row)
      @output.print("#{row[:section_name]}:")
      entry = SacSections::GroupEntry.new(row)
      entry_valid = entry.valid?
      @output.print(entry_valid ? " ✅\n" : " ❌ #{entry.errors}\n")
      if entry_valid
        entry.import!
      end
    end
  end
end
