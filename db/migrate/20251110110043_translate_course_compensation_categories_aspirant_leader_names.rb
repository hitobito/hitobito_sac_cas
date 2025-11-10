# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class TranslateCourseCompensationCategoriesAspirantLeaderNames < ActiveRecord::Migration[8.0]
  def up
    CourseCompensationCategory.add_translation_fields!(
      {
        name_leader_aspirant: {type: :string},
        name_assistant_leader_aspirant: {type: :string}
      }
    )

    CourseCompensationCategory.connection.execute(
      <<~SQL
        UPDATE course_compensation_category_translations
        SET name_leader_aspirant = course_compensation_categories.name_leader_aspirant,
        name_assistant_leader_aspirant = course_compensation_categories.name_assistant_leader_aspirant
        FROM course_compensation_categories
        WHERE course_compensation_category_translations.course_compensation_category_id = course_compensation_categories.id AND
        course_compensation_category_translations.locale = 'de'
      SQL
    )

    remove_column :course_compensation_categories, :name_leader_aspirant
    remove_column :course_compensation_categories, :name_assistant_leader_aspirant
  end

  def down
    add_column :course_compensation_categories, :name_leader_aspirant, :string
    add_column :course_compensation_categories, :name_assistant_leader_aspirant, :string

    CourseCompensationCategory.connection.execute(
      <<~SQL
        UPDATE course_compensation_categories
        SET name_leader_aspirant = course_compensation_category_translations.name_leader_aspirant,
        name_assistant_leader_aspirant = course_compensation_category_translations.name_assistant_leader_aspirant
        FROM course_compensation_category_translations
        WHERE course_compensation_category_translations.course_compensation_category_id = course_compensation_categories.id AND
        course_compensation_category_translations.locale = 'de'
      SQL
    )

    remove_column :course_compensation_category_translations, :name_leader_aspirant
    remove_column :course_compensation_category_translations, :name_assistant_leader_aspirant
  end
end
