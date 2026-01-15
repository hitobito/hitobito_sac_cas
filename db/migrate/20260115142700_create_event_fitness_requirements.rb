# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateEventFitnessRequirements < ActiveRecord::Migration[8.0]
  def change
    create_table :event_fitness_requirements do |t|
      t.integer :order
      t.timestamps
      t.datetime :deleted_at
    end

    add_column :events, :fitness_requirement_id, :bigint
    add_index :events, :fitness_requirement_id

    reversible do |dir|
      dir.up do
        Event::FitnessRequirement.create_translation_table!(
          label: { type: :string, null: false },
          short_description: { type: :string, null: true },
          description: { type: :text, null: true },
        )
      end

      dir.down do
        Event::FitnessRequirement.drop_translation_table!
      end
    end
  end
end
