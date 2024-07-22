# frozen_string_literal: true

class SacImports::SourceFile
  AVAILABLE_SOURCES = [:NAV1, :NAV2, :NAV3, :WSO21, :WSO22].freeze

  def path(source_name)
    files = Dir.glob("#{source_name}_*.xlsx")
    if files.empty?
      puts "No files found matching the pattern"
      exit
    end

    Rails.root.join("tmp", "xlsx", "#{files.first}.xlsx")
  end
end
