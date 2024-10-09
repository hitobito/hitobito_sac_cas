# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class RolesImporter
    REPORT_HEADERS = [
      :navision_id,
      :person_name,
      :valid_from,
      :valid_until,
      :target_group,
      :target_role,
      :message,
      :warning,
      :error
    ].freeze

    def initialize(output: $stdout, role_type:)
      @output = output
      @role_type = role_type
      @source_file = SacImports::CsvSource.new(:NAV2)
      @csv_report = SacImports::CsvReport.new(:"nav2-1_roles", REPORT_HEADERS)
      @failed_person_ids = []
    end

    def create
      if @role_type == :membership
        memberships_importer.create
        additional_memberships_importer.create
      end
      @csv_report.finalize(output: @output)
    end

    private

    def memberships_importer
      Roles::MembershipsImporter
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
  end
end
