# frozen_string_literal: true

class SacImports::CsvSourceFile
  NIL_VALUES = ["", "NULL", "null", "Null"].freeze
  SOURCE_HEADERS =
    {NAV1: {
      navision_id: "No_",
      person_name: "Name",
      navision_membership_years: "Vereinsmitgliederjahre",
    },
    NAV2: {
      navision_id: "Mitgliedernummer",
      household_key: "Familien-Nr.",
      group_navision_id: "Sektion",
      person_name: "Name",
      navision_membership_years: "Vereinsmitgliederjahre"
    },
    NAV3: {},
    WSO21: {},
    WSO22: {}}.freeze

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
    if files.empty?
      raise("No source file #{@source_name}_*.csv found in RAILS_CORE_ROOT/tmp/sac_imports_src/.")
    end

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
      raise "Invalid source name: #{@source_name}\navailable sources: #{AVAILABLE_SOURCES.map(&:to_s).join(", ")}"
    end
  end
end
