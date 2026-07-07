# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RenameEventDisciplinesToEventActivities < ActiveRecord::Migration[8.0]
  def change
    rename_table :event_disciplines, :event_activities
    rename_table :events_disciplines, :events_activities
    rename_table :event_discipline_translations, :event_activity_translations

    rename_column :event_activity_translations, :event_discipline_id, :event_activity_id
    rename_column :events_activities, :discipline_id, :activity_id
    rename_column :event_approval_commission_responsibilities, :discipline_id, :activity_id
  end
end
