# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav222RolesNonMembershipImporter < Nav2Base
    self.source_file = :NAV22
    self.report_name = "nav2_2_2-roles-non_membership"

    private

    def run_import
      log_count_change(:roles) do
        Roles::Nav22NonMembershipImporter
          .new(csv_source: @source_file,
            output: @output,
            csv_report: @csv_report,
            failed_person_ids: @failed_person_ids)
          .create
      end
    end
  end
end
