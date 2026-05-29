# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Xlsx
  class SacStatistics < Plain
    attr_reader :range

    def initialize(range)
      @range = range
    end

    private

    def build_sheets
      build_mitglied_statistics_sheet
      build_monthly_mutations_sheet
      build_sektion_mitglieder_sheet
      build_sektion_mitglieder_and_zusatzmitglieder_sheet
      build_sektion_zusatzmitglieder_sheet
    end

    def build_mitglied_statistics_sheet
      build_sheet(translate("mitglieder_statistics.sheet_name")) do |sheet|
        Export::Xlsx::MitgliederStatistics::Sheet.new(
          self,
          range,
          relevant_role_types: SacCas::MITGLIED_STAMMSEKTION_ROLES
        ).generate
      end
    end

    def build_monthly_mutations_sheet
      build_sheet(translate("monthly_mutations.sheet_name")) do |sheet|
        MonthlyMutationsSheet.new(self, range).generate
      end
    end

    def build_sektion_mitglieder_sheet
      build_sheet(translate("sektion_mitglieder.sheet_name")) do |sheet|
        SektionMitgliederSheet.new(self, range).generate
      end
    end

    def build_sektion_mitglieder_and_zusatzmitglieder_sheet
      build_sheet(translate("sektion_mitglieder_and_zusatzmitglieder.sheet_name")) do |sheet|
        SektionMitgliederAndZusatzmitgliederSheet.new(self, range).generate
      end
    end

    def build_sektion_zusatzmitglieder_sheet
      build_sheet(translate("sektion_zusatzmitglieder.sheet_name")) do |sheet|
        SektionZusatzmitgliederSheet.new(self, range).generate
      end
    end

    def translate(key, **options)
      I18n.t("export/xlsx/sac_statistics.#{key}", **options)
    end

    def group
      @group ||= Group.root
    end
  end
end
