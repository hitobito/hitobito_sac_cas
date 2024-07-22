# frozen_string_literal: true

class SacImports::SourceFile
  AVAILABLE_SOURCES = [:NAV1, :NAV2, :NAV3, :WSO21, :WSO22].freeze

  def initialize(source_name)
    assert_available_source(source_name)
    @source_name = source_name
  end

  def path
    files = Dir.glob("#{source_dir}/#{@source_name}_*.xlsx")
    if files.empty?
      raise("No source file #{@source_name}_*.xlsx found in RAILS_CORE_ROOT/tmp/xlsx/.")
    end

    Rails.root.join("tmp", "xlsx", "#{files.first}")
  end

  private

  def source_dir
    Rails.root.join("tmp", "xlsx")
  end

  def assert_available_source(source_name)
    unless AVAILABLE_SOURCES.include?(source_name)
      raise "Invalid source name: NAV42\navailable sources: #{AVAILABLE_SOURCES.map(&:to_s).join(', ')}"
    end
  end
end
