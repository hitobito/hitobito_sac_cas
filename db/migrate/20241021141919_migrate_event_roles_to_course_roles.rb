# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigrateEventRolesToCourseRoles < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL.squish
      UPDATE event_roles
      SET type = 'Event::Course::Role::Leader'
      WHERE type = 'Event::Role::Leader'
      AND participation_id IN (
        SELECT event_participations.id
        FROM event_participations
        INNER JOIN events ON event_participations.event_id = events.id
        WHERE events.type = 'Event::Course'
      );
    SQL

    execute <<-SQL.squish
      UPDATE event_roles
      SET type = 'Event::Course::Role::AssistantLeader'
      WHERE type = 'Event::Role::AssistantLeader'
      AND participation_id IN (
        SELECT event_participations.id
        FROM event_participations
        INNER JOIN events ON event_participations.event_id = events.id
        WHERE events.type = 'Event::Course'
      );
    SQL
  end
end
