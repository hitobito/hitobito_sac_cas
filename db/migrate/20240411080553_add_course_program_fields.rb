# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddCourseProgramFields < ActiveRecord::Migration[6.1]
  def change
    add_column :event_translations, :brief_description, :text
    add_column :event_translations, :specialities, :text
    add_column :event_translations, :similar_tours, :text
    add_column :event_translations, :program, :text

    add_column :events, :meals, :string
    add_column :events, :book_discount_code, :string
  end
end
