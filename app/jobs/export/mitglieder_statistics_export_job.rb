# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::MitgliederStatisticsExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:group_id, :from, :to]

  def initialize(user_id, group_id, filename, from, to, **)
    @group_id = group_id
    @from = from
    @to = to
    super(:xlsx, user_id, filename: filename, **)
  end

  def data
    Export::Xlsx::MitgliederStatistics.new(group, @from..@to).generate
  end

  def group
    @group ||= Group::SektionsMitglieder.find(@group_id)
  end
end
