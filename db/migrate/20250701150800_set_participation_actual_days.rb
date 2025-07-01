# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SetParticipationActualDays < ActiveRecord::Migration[7.0]
  def up
    execute(
      <<~SQL
        UPDATE event_participations
        SET actual_days = events.training_days
        FROM events, event_roles
        WHERE events.id = event_participations.event_id
        AND event_roles.participation_id = event_participations.id
        AND event_participations.actual_days IS NULL
        AND events.training_days IS NOT NULL
        AND event_roles.type = 'Event::Course::Role::Participant'
      SQL
    )
  end
end
