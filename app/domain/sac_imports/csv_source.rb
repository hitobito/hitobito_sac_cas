# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SacImports::CsvSource
  SOURCE_DIR = Rails.root.join("tmp", "sac_imports_src").freeze
  NIL_VALUES = ["", "NULL", "null", "Null", "1900-01-01"].freeze

  SOURCES = {
    NAV1: Nav1,
    NAV2a: Nav2a,
    NAV2b: Nav2b,
    NAV3: Nav3,
    NAV6: Nav6,
    NAV17: Nav17,
    NAV18: Nav18,
    WSO21: Wso2,
    CHIMP_1: Chimp,
    CHIMP_2: Chimp,
    CHIMP_3: Chimp
  }.freeze

  AVAILABLE_SOURCES = SOURCES.keys.freeze

  attr_reader :source_name

  def initialize(source_name, source_dir: SOURCE_DIR)
    @source_dir = source_dir
    @source_name = source_name
    assert_available_source
  end

  def rows(filter: nil)
    data = []
    CSV.foreach(path, headers: false, encoding: "bom|utf-8") do |raw_row|
      row = process_row(raw_row)
      next unless filter.blank? || filter_match?(row, filter)

      if block_given?
        yield row
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
    filter.all? { |key, value| row.public_send(key)&.match?(value) }
  end

  def process_row(row)
    check_row_size(row)
    clean_row = row.map { |cell| clean_value(cell) }
    column_data_class.new(*clean_row)
  end

  def check_row_size(row)
    valid_sizes = column_data_class.try(:valid_sizes) || [column_data_class.members.size]
    unless valid_sizes.include?(row.size)
      raise "#{@source_name}: wrong number of columns, got #{row.size} expected #{valid_sizes.join(" or ")}"
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

  def column_data_class
    SOURCES[@source_name]
  end

  def assert_available_source
    unless AVAILABLE_SOURCES.include?(@source_name)
      raise "Invalid source name: #{@source_name}\nAvailable sources: #{AVAILABLE_SOURCES.map(&:to_s).join(", ")}"
    end
  end
end
