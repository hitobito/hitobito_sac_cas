# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddAccountCompletions < ActiveRecord::Migration[7.1]
  def change
    create_table(:account_completions) do |t|
      t.belongs_to :person, null: false, index: {unique: true}
      t.string :token, index: true
      t.timestamps
    end
  end
end
