# frozen_string_literal: true

class SacImports::CsvSource
  NIL_VALUES = ["", "NULL", "null", "Null"].freeze
  SOURCE_HEADERS = {
    NAV1: {
      navision_id: "No_",
      navision_name: "Name",
      navision_membership_years: "Vereinsmitgliederjahre",
      first_name: "First Name",
      last_name: "Surname",
      address_care_of: "Name 2",
      postbox: "Address 2",
      address: "Address",
      street: "Street Name",
      housenumber: "Street No_",
      country: "Country_Region Code",
      town: "City",
      zip_code: "Post Code",
      email: "E-Mail",
      phone_private: "Phone No_",
      phone_mobile: "Mobile Phone No_",
      phone_fax: "Fax No_",
      birthday: "Date of Birth",
      gender: "Geschlecht",
      language: "Language Code",
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
    }
    # NAV3: {},
    # WSO21: {},
    # WSO22: {}
  }.freeze

  AVAILABLE_SOURCES = SOURCE_HEADERS.keys.freeze

  def initialize(source_name)
    @source_name = source_name
    assert_available_source
  end

  def rows
    data = []
    CSV.foreach(path, headers: true) do |row|
      data << process_row(row)
    end
    data
  end

  private

  def process_row(row)
    row = row.to_h
    hash = {}
    headers.keys.each do |header_key|
      value = row[headers[header_key]]
      value = nil if NIL_VALUES.include?(value)

      hash[header_key] = value
    end
    hash
  end

  def path
    files = Dir.glob("#{source_dir}/#{@source_name}_*.csv")
    raise("No source file #{@source_name}_*.csv found in #{source_dir}.") if files.empty?

    source_dir.join(files.first)
  end

  def headers
    SOURCE_HEADERS[@source_name]
  end

  def source_dir
    Rails.root.join("tmp", "sac_imports_src")
  end

  def assert_available_source
    unless AVAILABLE_SOURCES.include?(@source_name)
      raise "Invalid source name: #{@source_name}\nAvailable sources: #{AVAILABLE_SOURCES.map(&:to_s).join(", ")}"
    end
  end
end
