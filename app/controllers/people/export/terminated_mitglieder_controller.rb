# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Export::TerminatedMitgliederController < People::Export::PopoverExportableController

  private

  def entry
    @entry ||= People::Export::TerminatedMitgliederForm.new(model_params)
  end

  def model_params
    params
      .require(:people_export_terminated_mitglieder_form)
      .permit(:from, :to)
      .merge(group: group)
  end

  def enqueue_job(filename)
    Export::TerminatedMitgliederExportJob.new(
      current_person.id,
      group.id,
      filename,
      entry.from,
      entry.to
    ).enqueue!
  end

  def rerender_form(status)
    render turbo_stream: turbo_stream.replace(
      "terminated_mitglieder_form",
      partial: "people/export/popover_terminated_mitglieder",
      locals: {model: entry}
    ), status: status
  end

  def group
    @group ||= Group.find(params[:group_id])
  end
end
