# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export
  class SacCoursesController < People::Export::PopoverExportableController
    def create
      authorize_export!

      export_in_background
    end

    private

    def enqueue_job(filename)
      Export::SacCoursesExportJob.new(
        current_person.id,
        filename,
        year
      ).enqueue!
    end

    def authorize_export!
      authorize!(:download_statistics, group)
    end

    def redirection_target
      group_path(group)
    end

    def filename
      config = [
        translate("filename"),
        year
      ]
      "#{config.join("_")}-#{Date.current.strftime("%Y%m%d")}"
    end

    def year
      params.require(:export).fetch(:year, Date.current.year).to_i
    end
  end
end
