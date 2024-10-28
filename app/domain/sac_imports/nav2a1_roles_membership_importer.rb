# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav2a1RolesMembershipImporter < Nav2Base
    self.source_file = :NAV2a
    self.report_name = "nav2a1-roles-membership"

    private

    def run_import
      log_counts_delta(@csv_report, Role.unscoped,
        "Aktuell gültig" => Role.all,
        "Gekündigt" => Role.unscoped.where(terminated: true)) do
        memberships_importer.create
        additional_memberships_importer.create
      end
    end

    def memberships_importer
      Roles::Nav2a1MembershipsImporter
        .new(csv_source: @source_file,
          output: @output,
          csv_report: @csv_report)
    end

    def additional_memberships_importer
      Roles::Nav2a1AdditionalMembershipsImporter
        .new(csv_source: @source_file,
          output: @output,
          csv_report: @csv_report)
    end
  end
end
