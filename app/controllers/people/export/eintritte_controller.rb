# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People::Export
  class EintritteController < ApplicationController
    include AsyncDownload
    include PopoverExportable

    private

    def entry
      @entry ||= People::Export::EintritteForm.new(model_params)
    end

    def model_params
      params
        .require(:people_export_eintritte_form)
        .permit(:from, :to)
        .merge(group: group)
    end

    def enqueue_job(filename)
      Export::EintritteExportJob.new(
        current_person.id,
        group.id,
        filename,
        entry.from,
        entry.to
      ).enqueue!
    end

    def rerender_form(status)
      render turbo_stream: turbo_stream.replace(
        "eintritte_form",
        partial: "people/export/popover_eintritte",
        locals: {model: entry}
      ), status: status
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
end
