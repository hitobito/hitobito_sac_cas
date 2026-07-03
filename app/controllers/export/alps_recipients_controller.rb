# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export
  class AlpsRecipientsController < People::Export::PopoverExportableController
    private

    def enqueue_job(filename)
      Export::AlpsRecipientsExportJob.new(
        current_person.id,
        filename,
        entry.reference_date,
        entry.new_entries_from
      ).enqueue!
    end

    def authorize_export!
      authorize!(:download_statistics, group)
    end

    def redirection_target
      group_path(group)
    end

    def render_unprocessable
      render turbo_stream: turbo_stream.replace(
        "alps_recipients_form",
        partial: "groups/popover_alps_recipients",
        locals: {model: entry, group: group}
      ), status: :unprocessable_content
    end

    def entry
      @entry ||= People::Export::AlpsRecipientsForm.new(model_params)
    end

    def model_params
      params
        .require(:people_export_alps_recipients_form)
        .permit(:reference_date, :new_entries_from)
    end

    def filename
      config = [
        translate("filename"),
        entry.reference_date.strftime("%Y%m%d")
      ]
      "#{config.join("_")}-#{Date.current.strftime("%Y%m%d")}"
    end
  end
end
