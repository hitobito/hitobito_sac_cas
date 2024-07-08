# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class MitgliederExportsController < ApplicationController
  include AsyncDownload

  def create
    authorize!(:export_mitglieder, group)

    with_async_download_cookie(:csv, filename, redirection_target: group) do |filename|
      SacCas::Export::MitgliederExportJob.new(current_person.id, group.id,
        filename: filename).enqueue!
    end
  end

  private

  def group
    @group ||= Group.find(params[:group_id])
  end

  def filename
    "Adressen_#{group.navision_id_padded}"
  end
end
