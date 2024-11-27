# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  REFERENCE_DATE = Date.new(2024, 12, 31)

  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Nav2 = Data.define(
    :navision_id, # "Kontaktnummer",
    :family_id, # "Familiennummer",
    :valid_from, # "GültigAb",
    :valid_until, # "GültigBis",
    :layer_type, # "Layer",
    :group_level1, # "Gruppe_Lvl_1",
    :group_level2, # "Gruppe_Lvl_2",
    :group_level3, # "Gruppe_Lvl_3",
    :group_level4, # "Gruppe_Lvl_4",
    :role, # "Rolle",
    :role_description, # "Zusatzbeschrieb",
    :membership_years, # "Vereinsmitgliederjahre",
    :person_name, # "Name",
    :nav_verteilercode, # "NAV_Verteilercode",
    :beitragskategorie, # "Beitragskategorie",
    :sektionscode, # "Sektioncode",
    :sektionsname, # "Sektionname",
    :membership_kind # "Mitgliederart"
  ) do
    def group_hierarchy
      to_h.slice(:group_level1, :group_level2, :group_level3, :group_level4)
        .values.reverse.drop_while(&:nil?).reverse
    end

    def group_path = group_hierarchy.join(" > ")

    def active?
      Role.new(start_on: valid_from, end_on: valid_until)
        .active?(REFERENCE_DATE)
    end

    def terminated?
      return false if valid_until.blank?

      Date.parse(valid_until) < REFERENCE_DATE
    end
  end
end
