# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People::Export
  class JubilareController < PopoverExportableController
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

    def enqueue_job(filename)
      Export::JubilareExportJob.new(
        current_person.id,
        group.id,
        filename,
        entry.reference_date,
        entry.membership_years
      ).enqueue!
    end

    def render_unprocessable
      render turbo_stream: turbo_stream.replace(
        "jubilare_form",
        partial: "people/export/popover_jubilare",
        locals: {model: entry}
      ), status: :unprocessable_content
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
end
