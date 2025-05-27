# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class Nav2a1AdditionalMembershipsImporter < Nav2aBase
    self.rows_filter = {role: /^Mitglied \(Zusatzsektion\).+/}

    private

    def create_role(row, membership_group, person, beitragskategorie)
      role = Group::SektionsMitglieder::MitgliedZusatzsektion.unscoped.where(
        group: membership_group,
        person: person,
        beitragskategorie: beitragskategorie,
        start_on: row.start_on,
        end_on: row.end_on
      ).first_or_initialize(
        beitragskategorie: beitragskategorie
      )
      role.write_attribute(:terminated, true) if row.terminated?

      save_role!(role, row) if role.new_record?
    end

    def extract_beitragskategorie(row)
      kat = row.role[/^Mitglied \(Zusatzsektion\) \((.*?)\)/, 1]
      kat = BEITRAGSKATEGORIE_MAPPING[kat]
      return kat if kat.present?

      report(row, nil, error: "Invalid Beitragskategorie in '#{row.role}'")
      false
    end
  end
end
