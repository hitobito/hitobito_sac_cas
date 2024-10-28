# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SacImports::CsvSource
  SOURCE_DIR = Rails.root.join("tmp", "sac_imports_src").freeze
  NIL_VALUES = ["", "NULL", "null", "Null", "1900-01-01"].freeze

  SOURCE_HEADERS = {
    NAV1: Nav1,
    NAV2a: Nav2a,
    NAV2b: Nav2b,
    NAV3: Nav3,
    NAV6: Nav6,

    # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
    # they must match the order of the columns in the CSV files
    WSO21: {
      um_id: "UM_ID",
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

  def initialize(source_name, headers: false, source_dir: SOURCE_DIR)
    @source_dir = source_dir
    @source_name = source_name
    @headers = headers
    assert_available_source
  end

  def rows(filter: nil)
    data = []
    CSV.foreach(path, headers: @headers, encoding: "bom|utf-8") do |raw_row|
      row = process_row(raw_row)
      next unless filter.blank? || filter_match?(row, filter)

      if block_given?
        yield rows
      else
        data << row
      end
    end
    data unless block_given?
  end

  def lines_count
    `wc -l "#{path}"`.strip.split(" ")[0].to_i
  end

  private

  def filter_match?(row, filter)
    filter.all? { |key, value| value_for_key(row, key)&.match?(value) }
  end

  def validate_key(row, key)
    valid_keys = row.respond_to?(:keys) ? row.keys : row.members

    raise "Key '#{key}' not found in row: #{row.keys.inspect}" unless valid_keys.include?(key)
  end

  def value_for_key(row, key)
    validate_key(row, key)
    row.respond_to?(:keys) ? row[key] : row.public_send(key)
  end

  def process_row(row)
    if @headers
      raise "Headers are only supported when datasource is defined as a hash" unless
        headers.respond_to?(:keys)
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
    else
      check_row_size(row)
      clean_row = row.map { |cell| clean_value(cell) }
      headers.respond_to?(:keys) ? headers.keys.zip(clean_row).to_h : headers.new(*clean_row)
    end
  end

  def check_row_size(row)
    expected_cols = headers.respond_to?(:keys) ? headers.keys.size : headers.members.size
    if row.size != expected_cols
      raise "#{@source_name}: wrong number of columns, got #{row.size} expected #{expected_cols}"
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
