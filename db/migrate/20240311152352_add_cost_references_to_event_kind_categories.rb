# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddCostReferencesToEventKindCategories < ActiveRecord::Migration[6.1]
  def change # rubocop:disable Metrics/MethodLength
    change_table(:event_kind_categories) do |t|
      t.belongs_to :cost_center
      t.belongs_to :cost_unit
    end

    add_index(:event_kind_categories, [:cost_center_id, :cost_unit_id], unique: true)

    reversible do |dir|
      dir.up do
        insert_default(:cost_centers)
        insert_default(:cost_units)
        update_kind_categories
      end
      dir.down do
        remove_default(:cost_centers)
        remove_default(:cost_units)
      end
    end
    change_column_null(:event_kind_categories, :cost_center_id, false)
    change_column_null(:event_kind_categories, :cost_unit_id, false)
  end

  private

  def insert_default(kind)
    now = connection.adapter_name =~ /sqlite/i ? "datetime('now')" : "now()"
    return if select_value("SELECT COUNT(*) FROM #{kind};").positive? || Rails.env.test?
    execute "INSERT INTO #{kind} (code, created_at, updated_at) VALUES ('dummy', #{now}, #{now})"
  end

  def remove_default(kind)
    execute "DELETE FROM #{kind} WHERE code = 'dummy';"
  end


  def update_kind_categories
    execute <<~SQL
    UPDATE event_kind_categories SET
      cost_center_id = (SELECT id FROM cost_centers ORDER BY id LIMIT 1),
      cost_unit_id = (SELECT id FROM cost_units ORDER BY id LIMIT 1)
    SQL
  end
end
