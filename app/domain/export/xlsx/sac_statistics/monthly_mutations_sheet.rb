# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::SacStatistics
  class MonthlyMutationsSheet
    ROWS = [
      :month,
      :eintritte,
      :austritte,
      :aktive
    ]

    attr_reader :xlsx, :range

    delegate :add_row, to: :xlsx

    def initialize(xlsx, range)
      @xlsx = xlsx
      @range = range
    end

    def generate
      add_header_row
      each_month do |month_range|
        add_row([
          month_range.first.strftime("%m-%Y"),
          count_eintritte(month_range),
          count_austritte(month_range),
          count_aktive(month_range)
        ])
      end
    end

    private

    def each_month
      current = range.first
      while current <= range.last
        month_end = [current.end_of_month, range.last].min
        yield current..month_end
        current = current.end_of_month + 1.day
      end
    end

    def count_eintritte(month_range)
      Export::Tabular::People::EintritteScope
        .new(month_range, relevant_role_types:)
        .first_roles_by_person
        .count
    end

    def count_austritte(month_range)
      Export::Tabular::People::AustritteScope
        .new(month_range, relevant_role_types:)
        .last_roles_by_person
        .count
    end

    def count_aktive(month_range)
      Export::Tabular::People::AktiveScope
        .new(month_range.end, relevant_role_types:)
        .roles
        .count
    end

    def add_header_row
      add_row(ROWS.map { |key| translate(key) }, :title)
    end

    def translate(key, **options)
      I18n.t("export/xlsx/sac_statistics.monthly_mutations.#{key}", **options)
    end

    def relevant_role_types
      SacCas::MITGLIED_STAMMSEKTION_ROLES
    end
  end
end
