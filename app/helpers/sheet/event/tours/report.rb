#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  module Event::Tours
    class Report < Sheet::Base
      self.parent_sheet = Sheet::Event

      def title
        I18n.t("event.tours.reports.title", status: view.entry.report.status_label)
      end
    end
  end
end
