# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Export::JubilareController < ApplicationController
  include AsyncDownload

  def create
    authorize!(:index_people, group)

    entry.attributes = model_params
    if entry.valid?
      export_in_background
    else
      rerender_form(:unprocessable_content)
    end
  end

  private

  def entry
    @entry ||= People::Export::JubilareForm.new(model_params)
  end

  def model_params
    params
      .require(:people_export_jubilare_form)
      .permit(:reference_date, :membership_years)
      .merge(group: group)
  end

  def export_in_background
    with_async_download_cookie(
      :xlsx,
      filename,
      redirection_target: group_people_path(group, returning: true)
    ) do |name|
      enqueue_job(name)
    end
  end

  def enqueue_job(filename)
    Export::JubilareExportJob.new(
      current_person.id,
      group.id,
      filename,
      entry.reference_date,
      entry.membership_years
    ).enqueue!
  end

  def rerender_form(status)
    render turbo_stream: turbo_stream.replace(
      "jubilare_form",
      partial: "people/export/popover_jubilare",
      locals: {model: entry}
    ), status: status
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
      entry.reference_date.strftime("%Y%m%d")
    ]
    "#{config.join("_")}-#{Date.current.strftime("%Y%m%d")}"
  end
end
