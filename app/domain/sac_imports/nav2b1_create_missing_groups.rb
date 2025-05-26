# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  class Nav2b1CreateMissingGroups < Nav2Base
    self.source_file = :NAV2b
    self.report_name = "nav2b1-create-missing-groups"

    private

    def run_import
      log_counts_delta(@csv_report, Group.unscoped) do
        Roles::Nav2b1MissingGroupsImporter
          .new(csv_source: @source_file,
            output: @output,
            csv_report: @csv_report)
          .create
      end
    end
  end
end
