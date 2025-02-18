# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ReplaceCoursePricesWithDifferentCategories < ActiveRecord::Migration[7.0]
  def up
    change_table :events do |t|
      t.decimal :price_special, precision: 8, scale: 2
    end

    # migrate pricing to new fields
    execute <<-SQL
    UPDATE events
      SET price_member = price_js_active_member
      WHERE price_js_active_member IS NOT NULL;
    SQL

    execute <<-SQL
      UPDATE events
      SET price_regular = price_js_active_regular
      WHERE price_js_active_regular IS NOT NULL;
    SQL

    execute <<-SQL
      UPDATE events
      SET price_special = price_js_passive_member
      WHERE price_js_passive_member IS NOT NULL;
    SQL

    # migrate price category of participations
    execute <<-SQL
      UPDATE event_participations
      SET price_category = 0
      WHERE price_category = 3;
    SQL

    execute <<-SQL
      UPDATE event_participations
      SET price_category = 1
      WHERE price_category = 4;
    SQL

    execute <<-SQL
      UPDATE event_participations
      SET price_category = 3
      WHERE price_category = 5;
    SQL

    change_table :events do |t|
      t.remove :price_js_active_member, :price_js_active_regular, :price_js_passive_member, :price_js_passive_regular
    end

    add_column :event_kind_categories, :j_s_course, :boolean, default: :false
  end

  def down
    change_table :events do |t|
      t.decimal :price_js_active_member, precision: 8, scale: 2
      t.decimal :price_js_active_regular, precision: 8, scale: 2
      t.decimal :price_js_passive_member, precision: 8, scale: 2
      t.decimal :price_js_passive_regular, precision: 8, scale: 2

      t.remove :price_special
    end

    remove_column :event_kind_categories, :j_s_course
  end
end
