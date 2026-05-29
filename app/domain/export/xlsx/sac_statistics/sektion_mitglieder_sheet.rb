# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::SacStatistics
  class SektionMitgliederSheet
    BEITRAGSKATEGORIEN = %w[
      adult
      youth
      family_main
      family_adult
      family_child
    ].freeze

    ROWS = [
      :id,
      :name,
      :type,
      :total,
      *BEITRAGSKATEGORIEN
    ]

    GROUP_TYPES = [Group::Sektion, Group::Ortsgruppe].map(&:sti_name).freeze

    attr_reader :xlsx, :range

    delegate :add_row, to: :xlsx

    def initialize(xlsx, range)
      @xlsx = xlsx
      @range = range
    end

    def generate
      add_header_row
      sektionen.each do |group|
        add_sektion_row(group)
      end
      add_total_row
    end

    private

    def sektionen
      Group.active.where(type: GROUP_TYPES).order(:name)
    end

    def add_header_row
      add_row(ROWS.map { |key| translate(key) }, :title)
    end

    def add_sektion_row(group)
      add_row([
        group.id,
        group.name,
        group.class.label,
        *number_cells(group_counts(group.id))
      ])
    end

    def add_total_row
      add_row([
        translate(:total),
        nil,
        nil,
        *number_cells(total_counts)
      ])
    end

    def number_cells(numbers)
      [
        numbers.values.sum,
        *numbers.values_at(*BEITRAGSKATEGORIEN)
      ]
    end

    def counts_by_group
      @counts_by_group ||=
        roles
          .joins(:group, :person)
          .group("groups.layer_group_id", beitragskategorie_sql)
          .count
    end

    def roles
      Export::Tabular::People::AktiveScope
        .new(reference_date, relevant_role_types:)
        .roles
    end

    def beitragskategorie_sql
      Export::Xlsx::MitgliederStatistics::BeitragskategorieValue.new(reference_date).sql
    end

    def total_counts
      counts_by_group.each_with_object(Hash.new(0)) do |((group_id, value), count), hash|
        hash[value] += count
      end
    end

    def group_counts(group_id)
      Export::Xlsx::MitgliederStatistics::BeitragskategorieValue::VALUES
        .each_with_object({}) do |value, hash|
        hash[value] = counts_by_group[[group_id, value]] || 0
      end
    end

    def translate(key, **options)
      I18n.t("export/xlsx/sac_statistics.sektion_mitglieder.#{key}", **options)
    end

    def reference_date
      range.end
    end

    def relevant_role_types
      SacCas::MITGLIED_STAMMSEKTION_ROLES
    end
  end
end
