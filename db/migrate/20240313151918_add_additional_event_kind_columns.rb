# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddAdditionalEventKindColumns < ActiveRecord::Migration[6.1]
  def change
    change_table(:event_kinds) do |t|
      t.belongs_to :level, null: false
      t.belongs_to :cost_center
      t.belongs_to :cost_unit
      t.integer :maximum_participants
      t.integer :minimum_participants
      t.decimal :training_days, precision: 5, scale: 2

      t.string :season
      t.boolean :reserve_accommodation, null: false, default: true
      t.string :accomodation, null: false, default: :no_overnight
    end

    reversible do |dir|
      dir.up { update_kinds }
    end

    change_column_null(:event_kinds, :cost_center_id, false)
    change_column_null(:event_kinds, :cost_unit_id, false)
  end

  private

  def update_kinds
    execute <<~SQL
    UPDATE event_kinds SET
      cost_center_id = (SELECT id FROM cost_centers ORDER BY id LIMIT 1),
      cost_unit_id = (SELECT id FROM cost_units ORDER BY id LIMIT 1)
    SQL
  end
end
