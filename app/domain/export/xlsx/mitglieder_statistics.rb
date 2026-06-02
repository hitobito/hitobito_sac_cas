# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Xlsx
  class MitgliederStatistics < Plain
    attr_reader :group, :range

    def initialize(group, range)
      @group = group
      @range = range
    end

    private

    def build_sheets
      build_sheet(translate(:sheet_name)) do
        Sheet.new(self, range, group).generate
      end
    end

    def translate(key, **options)
      I18n.t("export/xlsx/mitglieder_statistics.#{key}", **options)
    end
  end
end
