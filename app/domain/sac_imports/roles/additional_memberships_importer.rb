# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class AdditionalMembershipsImporter < ImporterBase
    BEITRAGSKATEGORIE_MAPPING = {
      "Einzel" => :adult,
      "Jugend" => :youth,
      "Frei Fam" => :family,
      "Familie" => :family,
      "Frei Kind" => :family
    }

    SECTION_OR_ORTSGRUPPE_GROUP_TYPE_NAMES = [Group::Sektion.sti_name,
      Group::Ortsgruppe.sti_name].freeze

    def initialize(csv_source:, csv_report:, output: $stdout, failed_person_ids: [])
      @rows_filter = {role: /^Mitglied \(Zusatzsektion\).+/}
      super
    end

    private

    def process_row(row)
      super do |person|
        # skip todo row
        membership_group = fetch_membership_group(row, person)
        return false if membership_group.blank?

        beitragskategorie = extract_beitragskategorie(row)
        return false if beitragskategorie.blank?

        role = create_additional_membership_role(row, membership_group, person, beitragskategorie)
        return false if role.blank?

        report(row, person, message: "Additional Membership role created")
        true
      end
    end

    def create_additional_membership_role(row, membership_group, person, beitragskategorie)
      role = Group::SektionsMitglieder::MitgliedZusatzsektion.new(group: membership_group,
        person: person,
        beitragskategorie: beitragskategorie,
        start_on: row[:valid_from],
        end_on: row[:valid_until])

      save_role!(role, row)
    end

    def extract_beitragskategorie(row)
      kat = row[:role][/^Mitglied \(Zusatzsektion\) \((.*?)\)/, 1]
      kat = BEITRAGSKATEGORIE_MAPPING[kat]
      return kat if kat.present?

      report(row, nil, error: "Invalid Beitragskategorie in '#{row[:role]}'")
      false
    end

    def fetch_membership_group(row, person)
      group_name = extract_group_name(row)
      parent_group = Group.find_by(name: group_name, type: SECTION_OR_ORTSGRUPPE_GROUP_TYPE_NAMES)
      if parent_group
        return Group::SektionsMitglieder.find_by(parent_id: parent_group.id)
      end

      report(row, person, error: "No Section/Ortsgruppe group found for '#{row[:group_level1]}'")
      nil
    end

    def extract_group_name(row)
      # if ortsgruppe
      if row[:group_level3] == "Mitglieder"
        return row[:group_level2]
      end

      row[:group_level1]
    end
  end
end
