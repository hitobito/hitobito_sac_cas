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

    def initialize(csv_source:, csv_report:, output: $stdout)
      @output = output
      @csv_report = csv_report
      # @csv_source = csv_source
      @data = csv_source.rows(filter: rows_filter)
      @csv_source_person_ids = collect_csv_source_person_ids
      @sektionen_by_name = Group::Sektion.all.index_by(&:name)
      @ortsgruppen_by_name = Group::Ortsgruppe.all.index_by(&:name)
    end

    private

    def process_row(row)
      super do |person|
        membership_group = fetch_membership_group(row, person)
        return false if membership_group.blank?

        beitragskategorie = extract_beitragskategorie(row)
        return false if beitragskategorie.blank?

        create_role(row, membership_group, person, beitragskategorie)

        report(row, person, message: "#{title} role created")
      end
    end

    def fetch_membership_group(row, person)
      parent_group_class = sektion_or_ortsgruppe_class(row) ||
        report(row, person, error: "Unexpected layer type: '#{row.layer_type}'") && return

      parent_group = parent_group_class.find_by(name: row.group_level1) ||
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
