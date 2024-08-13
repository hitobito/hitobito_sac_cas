# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreatePersonDataQualityIssues < ActiveRecord::Migration[6.1]
  def change
    create_table :person_data_quality_issues do |t|
      t.belongs_to :person, null: false, index: true
      t.string :attr, null: false
      t.string :key, null: false
      t.integer :severity, null: false

      t.timestamps
    end

    add_index :person_data_quality_issues, %i[person_id attr key], unique: true
    add_column :people, :data_quality, :integer, default: 0

    Person.update_all(data_quality: 0)
    change_column_null :people, :data_quality, false
  end
end
