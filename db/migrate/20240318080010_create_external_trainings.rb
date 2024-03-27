# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class CreateExternalTrainings < ActiveRecord::Migration[6.1]
  def change
    create_table :external_trainings do |t|
      t.belongs_to :person, null: false
      t.belongs_to :event_kind

      t.string :name, null: false
      t.string :provider
      t.date :start_at, null: false
      t.date :finish_at, null: false
      t.decimal :training_days, scale: 1, precision: 5, null: false
      t.string :link
      t.string :remarks

      t.timestamps
    end
  end
end
