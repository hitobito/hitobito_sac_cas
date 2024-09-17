# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class MembershipsImporter
    def initialize(output, source_file, csv_report)
      @output = output
      @source_file = source_file
      @csv_report = csv_report
    end

    def create
      data = @source_file.rows
      data.each do |row|
        process_row(row)
      end
    end

    def process_row(row)
      @output.print("#{row[:navision_id]} (#{row[:name]}):")
      entry = MembershipEntry.new(row)
      @output.print(entry.valid? ? " ✅\n" : " ❌ #{entry.errors}\n")
      if entry.valid?
        entry.import!
      else
        @csv_report.add_row({
          navision_id: row[:navision_id],
          navision_name: row[:name],
          errors: entry.errors
        })
      end
    end
  end
end
