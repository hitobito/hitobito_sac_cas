# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class Importer
    REPORT_HEADERS = [
      :navision_id,
      :navision_name,
      :errors
    ]

    def initialize(output: $stdout)
      @output = output
      @source_file = CsvSource.new(:NAV2)
      @csv_report = CsvReport.new(:"4_roles", REPORT_HEADERS)
    end

    def create
      MembershipsImporter.new(@output, @source_file, @csv_report).create
      @csv_report.finalize(output: @output)
    end
  end
end
