# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddAdditionalEventColumns < ActiveRecord::Migration[6.1]
  def change
    change_table(:events) do |t|
      t.string :language
      t.belongs_to :cost_center, null: true
      t.belongs_to :cost_unit, null: true
      t.boolean :annual, null: false, default: true
      t.string :link_participants
      t.string :link_leaders
      t.string :link_survey

      t.string :accomodation, null: false, default: :no_overnight
      t.boolean :reserve_accommodation, null: false, default: true

      t.string :season
      t.string :start_point_of_time

      t.integer :minimum_age
    end
  end
end
