# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::SacStatisticsExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:from, :to]

  def initialize(user_id, filename, from, to, **)
    @from = from
    @to = to
    super(:xlsx, user_id, filename: filename, **)
  end

  def data
    Export::Xlsx::SacStatistics.new(@from..@to).generate
  end
end
