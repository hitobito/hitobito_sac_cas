# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class Nav2a1MembershipsImporter < Nav2aBase
    self.rows_filter = {role: /^Mitglied \(Stammsektion\).+/}

    private

    def create_role(row, membership_group, person, beitragskategorie)
      role = Group::SektionsMitglieder::Mitglied.unscoped.where(
        group: membership_group,
        person: person,
        start_on: row.valid_from,
        end_on: row.valid_until
      ).first_or_initialize(
        beitragskategorie: beitragskategorie,
        family_id: row.family_id
      )
      role.write_attribute(:terminated, true) if row.terminated?

      save_role!(role, row) if role.new_record?
    end

    def extract_beitragskategorie(row)
      kat = row.role[/^Mitglied \(Stammsektion\) \((.*?)\)/, 1]
      kat = BEITRAGSKATEGORIE_MAPPING[kat]
      return kat if kat.present?

      report(row, person, error: "Invalid Beitragskategorie in '#{row.role}'")
      false
    end
  end
end
