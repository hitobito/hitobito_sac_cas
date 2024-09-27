# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SacImports::CsvSource
  SOURCE_DIR = Rails.root.join("tmp", "sac_imports_src").freeze
  NIL_VALUES = ["", "NULL", "null", "Null"].freeze
  SOURCE_HEADERS = {
    NAV1: {
      navision_id: "No_",
      membership_years: "Vereinsmitgliederjahre",
      first_name: "First Name",
      last_name: "Surname",
      address_care_of: "Adresszusatz",
      postbox: "Postfach",
      street_name: "Street Name",
      housenumber: "Street No_",
      country: "Country_Region Code",
      town: "City",
      zip_code: "Post Code",
      email: "E-Mail",
      phone: "Phone No_",
      birthday: "Date of Birth",
      gender: "Geschlecht",
      language: "Language Code",
      social_media: "Social Media",
      family: "Family No_",
      person_type: "Personentyp",
      sac_remark_section_1: "Sektionsinfo 1 Bemerkung",
      sac_remark_section_2: "Sektionsinfo 2 Bemerkung",
      sac_remark_section_3: "Sektionsinfo 3 Bemerkung",
      sac_remark_section_4: "Sektionsinfo 4 Bemerkung",
      sac_remark_section_5: "Sektionsinfo 5 Bemerkung",
      sac_remark_national_office: "Geschäftsstelle Bemerkung"
    },
    NAV2: {
      navision_id: "Mitgliedernummer",
      household_key: "Familien-Nr.",
      group_navision_id: "Sektion",
      navision_name: "Name",
      navision_membership_years: "Vereinsmitgliederjahre"
    },
    # NAV3: {},
    NAV6: {
      navision_id: "NAV Sektions-ID",
      level_1_id: "Level 1",
      level_2_id: "Level 2",
      level_3_id: "Level 3",
      is_active: "Ist aktiv",
      section_name: "Name",
      address: "Adresse",
      postbox: "Zusätzliche Adresszeile",
      town: "Ort",
      zip_code: "PLZ",
      canton: "Kanton",
      phone: "Telefonnummer",
      email: "Haupt-E-Mail",
      has_jo: "Hat JO",
      youth_homepage: "Homepage Jugend",
      foundation_year: "Gründungsjahr",
      self_registration_without_confirmation: "Mit Freigabeprozess",
      termination_by_section_only: "Austritt nur durch Sektion",
      language: "Sprache",
      membership_configs: {
        section_fee_adult: "Sektionsbeitrag Mitgliedschaft Einzel",
        section_fee_family: "Sektionsbeitrag Mitgliedschaft Familie",
        section_fee_youth: "Sektionsbeitrag Mitgliedschaft Jugend",
        section_entry_fee_adult: "Eintrittsgebühr Mitgliedschaft Einzel",
        section_entry_fee_family: "Eintrittsgebühr Mitgliedschaft Familie",
        section_entry_fee_youth: "Eintrittsgebühr Mitgliedschaft Jugend",
        bulletin_postage_abroad: "Porto Ausland Sektionsbulletin",
        sac_fee_exemption_for_honorary_members: "Zentralverbandsgebührenerlass für Ehrenmitglieder",
        section_fee_exemption_for_honorary_members: "Sektionsgebührenerlass für Ehrenmitglieder",
        sac_fee_exemption_for_benefited_members: "Zentralverbandsgebührenerlass für Begünstigte",
        section_fee_exemption_for_benefited_members: "Sektionsgebührenerlass für Begünstigte",
        reduction_amount: "Reduktionsbetrag Mitgliedsjahre/Alter",
        reduction_required_membership_years: "Reduktion ab Mitgliedsjahren",
        reduction_required_age: "Reduktion ab Altersjahren"
      }
    },
    WSO21: {
      wso2_legacy_password_hash: "UM_USER_PASSWORD",
      wso2_legacy_password_salt: "UM_SALT_VALUE",
      navision_id: "ContactNo",
      gender: "Anredecode",
      first_name: "Vorname",
      last_name: "FamilienName",
      address_care_of: "Addresszusatz",
      address: "Strasse",
      postbox: "Postfach",
      town: "Ort",
      zip_code: "PLZ",
      country: "Land",
      phone: "TelefonMobil",
      phone_business: "TelefonG",
      language: "Korrespondenzsprache",
      email: "Mail",
      birthday: "Geburtsdatum",
      email_verified: "Email verified",
      role_basiskonto: "Basis Konto",
      role_abonnent: "Abonnent",
      role_gratisabonnent: "NAV_FSA2020FREE"
    }
    # WSO22: {}
  }.freeze

  AVAILABLE_SOURCES = SOURCE_HEADERS.keys.freeze

  def initialize(source_name, source_dir: SOURCE_DIR)
    @source_dir = source_dir
    @source_name = source_name
    assert_available_source
  end

  def rows
    data = []
    CSV.foreach(path, headers: true, encoding: "bom|utf-8") do |row|
      data << process_row(row)
    end
    data
  end

  private

  def process_row(row)
    row = row.to_h
    headers.each_with_object({}) do |(header_key, source_key), hash|
      if source_key.is_a?(Hash)
        sub_hash = source_key
        value = process_sub_hash(sub_hash, row)
      else
        value = row[source_key]
        value = clean_value(value)
      end
      hash[header_key] = value
    end
  end

  def process_sub_hash(sub_hash, row)
    sub_hash.each_with_object({}) do |(sub_header_key, source_key), sub_hash|
      sub_hash[sub_header_key] = clean_value(row[source_key])
    end
  end

  def clean_value(value)
    NIL_VALUES.include?(value) ? nil : value
  end

  def path
    files = Dir.glob("#{@source_dir}/#{@source_name}_*.csv")
    raise("No source file #{@source_name}_*.csv found in #{@source_dir}.") if files.empty?

    @source_dir.join(files.last)
  end

  def headers
    SOURCE_HEADERS[@source_name]
  end

  def assert_available_source
    unless AVAILABLE_SOURCES.include?(@source_name)
      raise "Invalid source name: #{@source_name}\nAvailable sources: #{AVAILABLE_SOURCES.map(&:to_s).join(", ")}"
    end
  end
end
