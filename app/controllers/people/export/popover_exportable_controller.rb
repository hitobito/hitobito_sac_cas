# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Export::PopoverExportableController < ApplicationController
  include AsyncDownload

  def create
    authorize!(:index_people, group)

    entry.attributes = model_params
    if entry.valid?
      export_in_background
    else
      render_unprocessable
    end
  end

  private

  def export_in_background
    with_async_download_cookie(
      :xlsx,
      filename,
      redirection_target: group_people_path(group, returning: true)
    ) do |name|
      enqueue_job(name)
    end
  end

  def render_unprocessable
    render turbo_stream: turbo_stream.replace(
      "period_form",
      partial: "people/export/popover_period",
      locals: {model: entry, url: export_url}
    ), status: :unprocessable_content
  end

  def entry
    @entry ||= People::Export::PeriodForm.new(model_params)
  end

  def model_params
    params
      .require(:people_export_period_form)
      .permit(:from, :to)
      .merge(group: group)
  end

  def export_url
    raise NotImplementedError
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def sektion
    group.layer_group
  end

  def filename
    config = [
      sektion.id,
      sektion.name,
      translate("filename"),
      entry.from.strftime("%Y%m%d"),
      entry.to.strftime("%Y%m%d")
    ]
    "#{config.join("_")}-#{Date.current.strftime("%Y%m%d")}"
  end
end
