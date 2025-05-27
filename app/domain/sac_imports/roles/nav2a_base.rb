# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class Nav2aBase < ImporterBase
    class_attribute :rows_filter

    BEITRAGSKATEGORIE_MAPPING = {
      "Einzel" => :adult,
      "Jugend" => :youth,
      "Frei Fam" => :family,
      "Familie" => :family,
      "Frei Kind" => :family
    }

    def initialize(csv_source:, csv_report:, output: $stdout, people_with_memberships: [])
      @output = output
      @csv_report = csv_report
      # @csv_source = csv_source
      @data = csv_source.rows(filter: rows_filter)
      @csv_source_person_ids = collect_csv_source_person_ids
      @sektionen_by_name = Group::Sektion.all.index_by(&:name)
      @ortsgruppen_by_name = Group::Ortsgruppe.all.index_by(&:name)
      @people_with_memberships = people_with_memberships
      @dead_people = CSV.read("/home/dilli/nextcloud-puzzle/projects/hitobito/hit-sac-cas/NAV2a_former-members-HIT-1002-verstorben.csv")
        .flatten.map { Integer(_1) }
    end

    private

    def process_row(row)
      if @dead_people.include?(navision_id(row))
        report(row, nil, warning: "Person is deceased, skipping...")
        return false
      end

      super do |person|
        report_person_has_memberships_already(row) if @people_with_memberships.include?(person.id)

        membership_group = fetch_membership_group(row, person)
        return false if membership_group.blank?

        beitragskategorie = extract_beitragskategorie(row)
        return false if beitragskategorie.blank?

        if create_role(row, membership_group, person, beitragskategorie)
          report(row, person, warning: "start_on korrigiert: '#{row.valid_from}' -> #{I18n.l(row.start_on)}") unless row.valid_from.present? && Date.parse(row.valid_from) == row.start_on
          report(row, person, message: "#{title} role created")
        end
      end
    end

    def report_person_has_memberships_already(row)
      report(row, nil, warning: "Person already has membership roles")
    end

    def fetch_membership_group(row, person)
      parent_group_class = sektion_or_ortsgruppe_class(row) ||
        report(row, person, error: "Unexpected layer type: '#{row.layer_type}'") && return

      group_name = case row.group_level1
      when "SAC Bregaglia" then "CAS Bregaglia"
      when "CAS Jura" then "CAS Jura (Ajoie)"
      when "CAS Val-De-Joux" then "CAS Val-de-Joux"
      when "SAC Engiadina Bassa" then "CAS Engiadina Bassa"
      when "CAS Diabl. Château d'Oex" then "CAS Diablerets Château d'Oex"
      when "CAS Dent-De-Lys" then "CAS Dent-de-Lys"
      else row.group_level1
      end

      parent_group = parent_group_class.find_by(name: group_name) ||
        report(row, person,
          error: "No #{parent_group_class} group found for '#{row.group_level1}'") && return

      Group::SektionsMitglieder.find_by(parent_id: parent_group.id)
    end

    def sektion_or_ortsgruppe_class(row)
      case row.layer_type
      when "Sektion"
        Group::Sektion
      when "Ortsgruppe"
        Group::Ortsgruppe
      end
    end
  end
end
