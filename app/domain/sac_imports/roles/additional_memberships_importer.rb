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

    def initialize(output: $stdout, csv_source:, csv_report: , failed_person_ids: [])
      @rows_filter = { role: /^Mitglied \(Zusatzsektion\).+/ }
      super
    end

    private

    def process_row(row)
      super(row) do |person|
        # skip todo row
        membership_group = fetch_membership_group(row, person)
        return false unless membership_group.present?

        beitragskategorie = extract_beitragskategorie(row)
        return false unless beitragskategorie.present? 
        
        role = create_additional_membership_role(row, membership_group, person, beitragskategorie)
        return false unless role.present?

        report(row, person, message: "Additional Membership role created")
        true
      end
    end

    def create_additional_membership_role(row, membership_group, person, beitragskategorie)
      role = Group::SektionsMitglieder::MitgliedZusatzsektion.new(group: membership_group,
                                                                  person: person,
                                                                  beitragskategorie: beitragskategorie,
                                                                  created_at: row[:valid_from])
      if Date.parse(row[:valid_until]).past?
        role.deleted_at = row[:valid_until]
      else
        role.delete_on = row[:valid_until]
      end

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
      parent_group = Group.find_by(name: row[:group_level1], type: SECTION_OR_ORTSGRUPPE_GROUP_TYPE_NAMES)
      if parent_group
        return Group::SektionsMitglieder.find_by(parent_id: parent_group.id)
      end

      report(row, person, error: "No Section/Ortsgruppe group found for '#{row[:group_level1]}'")
      nil
    end
  end
end
