# frozen_string_literal: true

class SacImports::CsvSourceFile
  SOURCE_HEADERS =
    {NAV1: {},
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
    headers = headers()
    data = []
    CSV.foreach(path, headers: true) do |row|
      row = row.to_h
      hash = {}
      headers.keys.each do |header_key|
        hash[header_key] = row[headers[header_key]]
      end
      data << hash
    end
    data
  end

  private

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
