# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav21RolesMembershipImporter < Nav2Base
    self.source_file = :NAV21
    self.report_name = "nav2_1-roles-membership"

    private

    def run_import
      log_count_change(:roles) do
        memberships_importer.create
        additional_memberships_importer.create
        benefited_importer.create
        honorary_importer.create
      end
    end

    def memberships_importer
      Roles::Nav21MembershipsImporter
        .new(csv_source: @source_file,
          output: @output,
          csv_report: @csv_report,
          failed_person_ids: @failed_person_ids)
    end

    def additional_memberships_importer
      Roles::AdditionalMembershipsImporter
        .new(csv_source: @source_file,
          output: @output,
          csv_report: @csv_report,
          failed_person_ids: @failed_person_ids)
    end

    def benefited_importer
      Roles::BenefitedImporter
        .new(csv_source: @source_file,
          output: @output,
          csv_report: @csv_report,
          failed_person_ids: @failed_person_ids)
    end

    def honorary_importer
      Roles::HonoraryImporter
        .new(csv_source: @source_file,
          output: @output,
          csv_report: @csv_report,
          failed_person_ids: @failed_person_ids)
    end
  end
end
