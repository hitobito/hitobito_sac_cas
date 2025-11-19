# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Xlsx
  class MitgliederStatistics
    attr_reader :group, :range

    def initialize(group, range)
      @group = group
      @range = range
    end

    def generate
      build_package.to_stream.read
    end

    private

    def build_package
      Axlsx::Package.new do |p|
        p.workbook do |wb|
          load_style_definitions(wb.styles)
          build_sheet(wb)
        end
      end
    end

    def build_sheet(wb)
      wb.add_worksheet(name: translate(:sheet_name)) do |sheet|
        @sheet = sheet
        setup_page(sheet)
        sections.each { |section| add_section(section) }
      end
    end

    def add_section(section)
      add_row([translate(section.title, **section.title_options)], :title)
      add_row
      add_row([translate(:total), nil, section.total])
      section.groupings.each do |grouping|
        add_row
        add_grouping(grouping, section.counts(grouping))
      end
      add_row
      add_row
    end

    def add_grouping(key, counts)
      add_row(["  #{translate(:thereof)}"])
      counts.each do |value, count|
        add_row([
          "  - #{translate("#{key}.label")}",
          translate("#{key}.#{value || "nil"}", default: value.to_s),
          count
        ])
      end
    end

    def add_row(row = [], style = :default)
      @sheet.add_row(row, style: @styles.fetch(style))
    end

    def sections
      [
        SectionActive,
        SectionEintritte,
        SectionAustritte
      ].map { |section| section.new(group, range) }
    end

    def setup_page(sheet)
      sheet.page_setup.set(
        paper_size: 9, # Default A4
        fit_to_height: 1,
        orientation: :landscape
      )
    end

    def load_style_definitions(workbook_styles)
      default = {font_name: Settings.xlsx.font_name, alignment: {horizontal: :left}}
      @styles = {}
      @styles[:default] = workbook_styles.add_style(default)
      @styles[:title] = workbook_styles.add_style(default.merge(b: true))
    end

    def translate(key, **options)
      I18n.t("export/xlsx/mitglieder_statistics.#{key}", **options)
    end
  end
end
