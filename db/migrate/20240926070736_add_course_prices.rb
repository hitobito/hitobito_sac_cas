# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddCoursePrices < ActiveRecord::Migration[6.1]
  def change
    change_table :events do |t|
      t.decimal :price_member, precision: 8, scale: 2
      t.decimal :price_regular, precision: 8, scale: 2
      t.decimal :price_subsidized, precision: 8, scale: 2
      t.decimal :price_js_active_member, precision: 8, scale: 2
      t.decimal :price_js_active_regular, precision: 8, scale: 2
      t.decimal :price_js_passive_member, precision: 8, scale: 2
      t.decimal :price_js_passive_regular, precision: 8, scale: 2
    end

    change_table :event_participations do |t|
      t.decimal :price, precision: 8, scale: 2, null: true
      t.integer :price_category, null: true
    end
  end
end
