# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddUmIdToPeople < ActiveRecord::Migration[7.0]
  def change
    add_column(:people, :um_id, :string)
    add_index(:people, :um_id, unique: true)
  end
end
