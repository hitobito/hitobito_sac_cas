# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class MembershipsImporter
    include Helper

    def initialize(output, source_file, csv_report, skipped_rows)
      @output = output
      @source_file = source_file
      @csv_report = csv_report
      @skipped_rows = skipped_rows
    end

    def create
      data = @source_file.rows
      data.each do |row|
        process_row(row)
      end
    end

    def process_row(row)
      import!(row, "memberships") unless skipped_row?(row) do |row|
        MembershipEntry.new(row)
      end
    end
  end
end
