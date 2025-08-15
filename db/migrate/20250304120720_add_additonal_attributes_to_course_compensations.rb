# frozen_string_literal: true

#  Copyright (c) 2012-2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddAdditonalAttributesToCourseCompensations < ActiveRecord::Migration[7.1]
  def change
    add_column :course_compensation_categories, :name_leader_aspirant, :string
    add_column :course_compensation_categories, :name_assistant_leader_aspirant, :string

    add_column :course_compensation_rates, :rate_leader_aspirant, :decimal, null: false, precision: 7, scale: 2, default: 0.0
    add_column :course_compensation_rates, :rate_assistant_leader_aspirant, :decimal, null: false, precision: 7, scale: 2, default: 0.0

    change_column_default :course_compensation_rates, :rate_leader, from: nil, to: 0.0
    change_column_default :course_compensation_rates, :rate_assistant_leader, from: nil, to: 0.0
  end
end
