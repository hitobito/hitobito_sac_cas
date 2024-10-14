# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class SetFamilyMainPerson < ImporterBase

    def initialize(csv_source: SacImports::CsvSource.new(:NAV2), output: $stdout)
      @rows_filter = {role: /^Mitglied \(Stammsektion\) \(Familie\)$/, valid_until: "2024-12-31"}
      csv_report = SacImports::CsvReport.new(:"nav2-1_roles", [])
      super(csv_source: csv_source, csv_report: csv_report, output: output)
    end

    def create
      reset_family_main_person
      set_family_main_person
    end

    private

    def set_family_main_person
      Person.where(id: @csv_source_person_ids).update_all(sac_family_main_person: true)
      p "Family main person count #{@csv_source_person_ids.count}"
    end

    def reset_family_main_person
      Person.where(id: @csv_source_person_ids).update_all(sac_family_main_person: false)
    end
  end
end
