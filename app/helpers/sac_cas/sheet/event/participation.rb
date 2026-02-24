#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::Sheet::Event::Participation
  extend ActiveSupport::Concern

  prepended do
    tab "global.tabs.info",
      :group_event_participation_path,
      if: :show_details

    tab "event.participations.tabs.history",
      :history_group_event_participation_path,
      if: :show_details
  end
end
