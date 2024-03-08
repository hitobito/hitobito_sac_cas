# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddCostModels < ActiveRecord::Migration[6.1]
  def change # rubocop:disable Metrics/MethodLength
    create_table(:cost_centers) do |t|
      t.string :code, null: false, unique: true
      t.datetime :deleted_at
      t.timestamps
    end

    create_table(:cost_units) do |t|
      t.string :code, null: false, unique: true
      t.datetime :deleted_at
      t.timestamps
    end

    add_index(:cost_centers, :code, unique: true)
    add_index(:cost_units, :code, unique: true)

    reversible do |dir|
      dir.up do
        CostCenter.create_translation_table! label: { type: :string, null: false }
        CostUnit.create_translation_table! label: { type: :string, null: false }
      end
      dir.down do
        CostCenter.drop_translation_table!
        CostUnit.drop_translation_table!
      end
    end
  end
end
