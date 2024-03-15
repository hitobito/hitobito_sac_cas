# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class CreateEventLevels < ActiveRecord::Migration[6.1]
  def change
    create_table :event_levels do |t|
      t.integer :code, null: false
      t.integer :difficulty, null: false

      t.datetime :deleted_at, precision: 6
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Event::Level.create_translation_table!(label: { type: :string, null: false })
      end

      dir.down do
        Event::Level.drop_translation_table!
      end
    end
  end
end
