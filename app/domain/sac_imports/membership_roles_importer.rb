# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class MembershipRolesImporter
    REPORT_HEADERS = [
      :navision_id,
      :person_name,
      :valid_from,
      :valid_until,
      :target_group_path,
      :target_role,
      :message,
      :warning,
      :error
    ].freeze

    def initialize(output: $stdout)
      @output = output
      @source_file = SacImports::CsvSource.new(:NAV2)
      @csv_report = SacImports::CsvReport.new(:"nav2-1_roles", REPORT_HEADERS)
      @skipped_rows = []
    end

    def create
      # Roles::MembershipsImporter.new(output: @output, csv_report: @csv_report, @failed_person_ids).create
      @csv_report.finalize(output: @output)
    end
  end
end
