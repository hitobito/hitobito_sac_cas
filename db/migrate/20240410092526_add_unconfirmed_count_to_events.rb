# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AddUnconfirmedCountToEvents < ActiveRecord::Migration[6.1]
  def change
    change_table(:events) do |t|
      t.integer :unconfirmed_count, default: 0, null: false
    end
  end
end
