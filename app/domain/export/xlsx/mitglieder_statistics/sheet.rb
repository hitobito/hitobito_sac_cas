# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics
  class Sheet
    attr_reader :xlsx, :range, :group, :relevant_role_types

    delegate :add_row, to: :xlsx

    def initialize(xlsx, range, group = nil, relevant_role_types: nil)
      @xlsx = xlsx
      @range = range
      @group = group
      @relevant_role_types = relevant_role_types
    end

    def generate
      sections.each { |section| add_section(section) }
    end

    private

    def sections
      [
        SectionActive,
        SectionEintritte,
        SectionAustritte
      ].map { |klass| klass.new(range, group, relevant_role_types:) }
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

    def translate(key, **options)
      I18n.t("export/xlsx/mitglieder_statistics.#{key}", **options)
    end
  end
end
