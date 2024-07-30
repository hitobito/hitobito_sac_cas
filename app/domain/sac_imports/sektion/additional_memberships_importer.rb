# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("lib", "import", "xlsx_reader.rb")

module SacImports
  module Sektion
    class AdditionalMembershipsImporter < MembershipsImporter
      self.headers = {
        navision_id: "Adressnummer",
        group_navision_id: "Sektion",
        beitragskategorie: "Bezeichnung Zusatzelement",
        joining_date: "Eintrittsdatum"
      }.freeze

      self.sheet_name = "Mapping Mitglied-Zusatzsektion"

      self.target_role_type = AdditionalMembership::TARGET_ROLE_TYPE

      private

      def import_row(row)
        membership = SacImports::Sektion::AdditionalMembership.new(
          row,
          group: membership_group(row),
          current_ability: root_ability
        )

        import_membership(membership, row)
      end

      def print_summary
        membership_groups.each_value do |group|
          active = target_role_type.where(group_id: group.id).count
          output.puts "#{group.parent} hat #{active} Zusatzmitgliedschaften"
        end

        output_list("Folgende Sektionen konnten nicht gefunden werden:", missing_sections.to_a)
      end
    end
  end
end
