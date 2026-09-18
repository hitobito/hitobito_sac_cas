# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateEventCachedLeaders < ActiveRecord::Migration[8.0]
  def change
    create_table :event_cached_leaders do |t|
      t.belongs_to :event, null: false
      t.belongs_to :person, null: false
      t.string :role_type, null: false
      t.index [:event_id, :person_id], unique: true
      t.index :role_type
    end

    reversible do |dir|
      dir.up { Event::CachedLeader.backfill_all }
    end
  end
end
