# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateEventDisciplines < ActiveRecord::Migration[8.0]
  def change
    create_table :event_disciplines do |t|
      t.integer :order
      t.belongs_to :parent, null: true
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :events_disciplines, id: false do |t|
      t.belongs_to :event, null: false
      t.belongs_to :discipline, null: false
      t.index [:event_id, :discipline_id], unique: true
    end

    reversible do |dir|
      dir.up do
        create_table :event_discipline_translations do |t|
          t.references :event_discipline, null: false, foreign_key: true, index: true
          t.string :locale, null: false

          t.string :label, null: false
          t.string :short_description, null: true
          t.text :description, null: true

          t.timestamps
        end
      end

      dir.down do
        drop_table :event_discipline_translations, if_exists: true
      end
    end
  end
end
