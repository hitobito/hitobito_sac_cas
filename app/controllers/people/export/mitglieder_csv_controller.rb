# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Export::MitgliederCsvController < ApplicationController
  include AsyncDownload

  def create
    authorize!(:index_people, group)

    with_async_download_cookie(:csv, filename,
      redirection_target: group_people_path(group, returning: true)) do |filename|
      Export::MitgliederCsvExportJob.new(
        current_person.id,
        group.layer_group_id,
        filename: filename
      ).enqueue!
    end
  end

  private

  def group
    @group ||= Group.find(params[:group_id])
  end

  def filename
    "Adressen_#{group.layer_group.id_padded}"
  end
end
