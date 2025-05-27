# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Nav2a2SetFamilyMainPerson
    include LogCounts

    def filter ={role: /\AMitglied \(Stammsektion\) \(Familie\)\z/, valid_until: "2024-12-31"}

    def initialize(output: $stdout)
      # PaperTrail.enabled = false # disable versioning for imports
      @output = output
      @data = SacImports::CsvSource.new(:NAV2a).rows(filter:)
      @csv_report = SacImports::CsvReport.new("nav2a2-set-family-main-person", [], output:)
    end

    def create
      log_counts_delta(@csv_report,
        "Main Person" => main_person_scope,
        "Not Main Person" => not_main_person_scope) do
        log_missing(main_person_ids_from_file - family_membership_people_ids)

        main_people_ids = main_person_ids_from_file & family_membership_people_ids
        set_family_main_person(main_people_ids)
      end
    end

    private

    def main_person_ids_from_file
      @main_person_ids_from_file ||= @data.map { |row| Integer(row.navision_id.to_s.sub(/^0*/, "")) }.uniq
    end

    def set_family_main_person(ids)
      Person.where(sac_family_main_person: true).update_all(sac_family_main_person: false)
      Person.where(id: ids).update_all(sac_family_main_person: true)
    end

    def family_membership_people_ids
      # relevant sind nur Familienmitglieder mit ungekündigter Mitgliedschaft
      # die bis Ende 2024 aktiv sind
      @family_membership_people_ids = Group::SektionsMitglieder::Mitglied
        .active(Date.new(2024, 12, 31))
        .where(terminated: false)
        .where(beitragskategorie: :family)
        .select(:person_id)
        .distinct
        .pluck(:person_id)
    end

    def main_person_scope
      Person.joins(:roles)
        .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name})
        .where(sac_family_main_person: true)
        .distinct
    end

    def not_main_person_scope
      Person.joins(:roles)
        .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name})
        .where(sac_family_main_person: [nil, false])
        .distinct
    end

    def log_missing(ids)
      return if ids.blank?

      @csv_report.log("Main people in file but without family membership: #{ids.join(",")}")
    end
  end
end
