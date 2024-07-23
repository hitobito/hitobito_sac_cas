# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class MembershipYearsReport
    HEADERS = {
      navision_id: "Mitgliedernummer",
      household_key: "Familien-Nr.",
      group_navision_id: "Sektion",
      navision_membership_years: "Vereinsmitgliederjahre"
    }.freeze

    def initialize(output: $stdout)
      @output = output
      @source_file = SourceFile.new(:NAV2).path
    end

    def create
      without_query_logging do
        Import::XlsxReader.read(@source_file, "aktive_mitglieder", headers: HEADERS) do |row|
        end
      end
    end
  end
end
