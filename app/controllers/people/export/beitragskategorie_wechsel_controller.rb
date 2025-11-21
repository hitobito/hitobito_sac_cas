# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People::Export
  class BeitragskategorieWechselController < PopoverExportableController
    private

    def enqueue_job(filename)
      Export::BeitragskategorieWechselExportJob.new(
        current_person.id,
        group.id,
        filename,
        entry.from,
        entry.to
      ).enqueue!
    end

    def export_url
      group_people_export_beitragskategorie_wechsel_path(group)
    end
  end
end
