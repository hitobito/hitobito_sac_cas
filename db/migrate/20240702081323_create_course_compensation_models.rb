# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateCourseCompensationModels < ActiveRecord::Migration[6.1]
  def change
    create_table :course_compensation_categories do |t|
      t.string :short_name, null: false, index: { unique: true }
      t.string :kind, null: false, default: :day
      t.string :description

      t.timestamps
    end

    create_table :course_compensation_rates do |t|
      t.belongs_to :course_compensation_category, null: false, index: { name: :course_compensation_rate_on_category_id }
      t.date :valid_from, null: false
      t.date :valid_to, null: true
      t.decimal :rate_leader, null: false, precision: 7, scale: 2
      t.decimal :rate_assistant_leader, null: false, precision: 7, scale: 2

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        CourseCompensationCategory.create_translation_table!(name_leader: { type: :string, null: false },
                                                             name_assistant_leader: { type: :string, null: false })
      end

      dir.down do
        CourseCompensationCategory.drop_translation_table!
      end
    end
  end
end
