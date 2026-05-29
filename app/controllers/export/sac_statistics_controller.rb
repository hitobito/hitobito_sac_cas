# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export
  class SacStatisticsController < People::Export::PopoverExportableController
    private

    def enqueue_job(filename)
      Export::SacStatisticsExportJob.new(
        current_person.id,
        filename,
        entry.from,
        entry.to
      ).enqueue!
    end

    def authorize_export!
      authorize!(:download_statistics, group)
    end

    def redirection_target
      group_people_path(group)
    end

    def export_url
      group_export_sac_statistics_path(group)
    end

    def filename
      config = [
        translate("filename"),
        entry.from.strftime("%Y%m%d"),
        entry.to.strftime("%Y%m%d")
      ]
      "#{config.join("_")}-#{Date.current.strftime("%Y%m%d")}"
    end
  end
end
