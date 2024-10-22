# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigrateEventRolesToCourseRoles < ActiveRecord::Migration[6.1]
  def change
    execute "UPDATE event_roles SET type = 'Event::Course::Role::Leader' WHERE type = 'Event::Role::Leader';"
    execute "UPDATE event_roles SET type = 'Event::Course::Role::AssistantLeader' WHERE type = 'Event::Role::AssistantLeader';"
  end
end
