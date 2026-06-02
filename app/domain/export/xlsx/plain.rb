# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Xlsx
  class Plain
    MAX_WORKSHEET_NAME_LENGTH = 31

    def generate
      build_package.to_stream.read
    end

    def add_row(row = [], style = :default)
      @current_sheet.add_row(row, style: @styles.fetch(style))
    end

    private

    attr_reader :styles

    def build_package
      Axlsx::Package.new do |p|
        p.workbook do |wb|
          @workbook = wb
          load_style_definitions(wb.styles)
          build_sheets
        end
      end
    end

    def build_sheets
      raise NotImplementedError, "Subclasses must implement build_sheets"
    end

    def build_sheet(name)
      @workbook.add_worksheet(name: name.truncate(MAX_WORKSHEET_NAME_LENGTH)) do |sheet|
        @current_sheet = sheet
        setup_page(sheet)
        yield
      end
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
  end
end
