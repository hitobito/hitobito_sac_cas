class MigrateEventRolesToCourseRoles < ActiveRecord::Migration[6.1]
  def change
    execute "UPDATE event_roles SET type = 'Event::Course::Role::Leader' WHERE type = 'Event::Role::Leader';"
    execute "UPDATE event_roles SET type = 'Event::Course::Role::AssistantLeader' WHERE type = 'Event::Role::AssistantLeader';"
  end
end
