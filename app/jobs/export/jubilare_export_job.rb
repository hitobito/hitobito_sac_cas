# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::JubilareExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:group_id, :reference_date, :membership_years]

  def initialize(user_id, group_id, filename, reference_date, membership_years = nil, **)
    @group_id = group_id
    @reference_date = reference_date
    @membership_years = membership_years
    super(:xlsx, user_id, filename: filename, **)
  end

  def data
    Export::Tabular::People::Jubilare.xlsx(group, @user_id, @reference_date, @membership_years)
  end

  def group
    @group ||= Group::SektionsMitglieder.find(@group_id)
  end
end
