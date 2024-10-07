# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class MembershipsImporter < ImporterBase

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
      @rows_filter = { role: /^Mitglied \(Stammsektion\).+/ }
      super
      @csv_source_person_ids = collect_csv_source_person_ids
    end
    
    def create
      delete_existing_membership_roles
      # reset_family_main_person
      super
    end

    private

    def process_row(row)
      super(row) do |person|
        membership_group = fetch_membership_group(row, person)
        return false unless membership_group.present?

        beitragskategorie = extract_beitragskategorie(row)
        # fail if invalid beitragskategorie
        
        create_membership_role(row, membership_group, person, beitragskategorie)
        set_family_main_person(person, row)
        clear_navision_import_role(person)
        report(row, person, message: "Membership role created")
        true
      end
    end

    def create_membership_role(row, membership_group, person, beitragskategorie)
      role = Group::SektionsMitglieder::Mitglied.new(group: membership_group,
                                                     person: person,
                                                     beitragskategorie: beitragskategorie,
                                                     created_at: row[:valid_from])
      if Date.parse(row[:valid_until]).past?
        role.deleted_at = row[:valid_until]
      else
        role.delete_on = row[:valid_until]
      end

      role.save!(context: :import)
    end

    def extract_beitragskategorie(row)
      kat = row[:role][/^Mitglied \(Stammsektion\) \((.*?)\)/, 1]
      BEITRAGSKATEGORIE_MAPPING[kat]
    end

    def fetch_membership_group(row, person)
      parent_group = Group.find_by(name: row[:group_level1], type: SECTION_OR_ORTSGRUPPE_GROUP_TYPE_NAMES)
      if parent_group
        return Group::SektionsMitglieder.find_by(parent_id: parent_group.id)
      end

      report(row, person, error: "No Section/Ortsgruppe group found for '#{row[:group_level1]}'")
      nil
    end

    def set_family_main_person(person, row)
      # if role active and  row Mitglied (Stammsektion) (Familie)
    end

    def delete_existing_membership_roles
      role_types = SacCas::MITGLIED_ROLES.map(&:sti_name)
      membership_roles = Role.with_deleted.where(type: role_types, person_id: @csv_source_person_ids)
      membership_roles.delete_all
    end

    def collect_csv_source_person_ids
      @data.map { |row| row[:navision_id].to_i }.uniq
    end
  end
end
