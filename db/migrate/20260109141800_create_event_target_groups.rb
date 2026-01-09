# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateEventTargetGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :event_target_groups do |t|
      t.integer :order
      t.belongs_to :parent, null: true
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :events_target_groups, id: false do |t|
      t.belongs_to :event, null: false
      t.belongs_to :target_group, null: false
      t.index [:event_id, :target_group_id], unique: true
    end

    reversible do |dir|
      dir.up do
        Event::TargetGroup.create_translation_table!(
          label: { type: :string, null: false },
          short_description: { type: :string, null: true },
          description: { type: :text, null: true },
        )
      end

      dir.down do
        Event::TargetGroup.drop_translation_table!
      end
    end
  end
end
