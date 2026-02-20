#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::EventParticipationsHelper
  def format_event_participation_created_at(participation)
    "#{f(participation.created_at.to_date)} #{f(participation.created_at.to_time)}"
  end

  def event_participation_table_options(t, event:, group:)
    if parent.possible_participation_states.any?
      t.sortable_attr(:state)
    end
  end
end
