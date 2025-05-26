# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  NAV6MEMBERSHIP_CONFIGS = [
    :section_fee_adult, # "Sektionsbeitrag Mitgliedschaft Einzel",
    :section_fee_family, # "Sektionsbeitrag Mitgliedschaft Familie",
    :section_fee_youth, # "Sektionsbeitrag Mitgliedschaft Jugend",
    :section_entry_fee_adult, # "Eintrittsgebühr Mitgliedschaft Einzel",
    :section_entry_fee_family, # "Eintrittsgebühr Mitgliedschaft Familie",
    :section_entry_fee_youth, # "Eintrittsgebühr Mitgliedschaft Jugend",
    :bulletin_postage_abroad, # "Porto Ausland Sektionsbulletin",
    :sac_fee_exemption_for_honorary_members, # "Zentralverbandsgebührenerlass für Ehrenmitglieder",
    :section_fee_exemption_for_honorary_members, # "Sektionsgebührenerlass für Ehrenmitglieder",
    :sac_fee_exemption_for_benefited_members, # "Zentralverbandsgebührenerlass für Begünstigte",
    :section_fee_exemption_for_benefited_members, # "Sektionsgebührenerlass für Begünstigte",
    :reduction_amount, # "Reduktionsbetrag Mitgliedsjahre/Alter",
    :reduction_required_membership_years, # "Reduktion ab Mitgliedsjahren",
    :reduction_required_age # "Reduktion ab Altersjahren"
  ].freeze

  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Nav6 = Data.define(
    :navision_id, # "NAV Sektions-ID",
    :level_1_id, # "Level 1",
    :level_2_id, # "Level 2",
    :level_3_id, # "Level 3",
    :is_active, # "Ist aktiv",
    :section_name, # "Name",
    :address, # "Adresse",
    :postbox, # "Zusätzliche Adresszeile",
    :town, # "Ort",
    :zip_code, # "PLZ",
    :canton, # "Kanton",
    :phone, # "Telefonnummer",
    :email, # "Haupt-E-Mail",
    :has_jo, # "Hat JO",
    :youth_homepage, # "Homepage Jugend",
    :foundation_year, # "Gründungsjahr",
    :self_registration_without_confirmation, # "Mit Freigabeprozess",
    :termination_by_section_only, # "Austritt nur durch Sektion",
    :language, # "Sprache",
    *NAV6MEMBERSHIP_CONFIGS,
    :has_bulletin_paper, # "Sektionsbulletin physisch",
    :has_bulletin_digital # "Sektionsbulletin digital",
  )
end
