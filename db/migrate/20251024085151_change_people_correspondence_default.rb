# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ChangePeopleCorrespondenceDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default(:people, :correspondence, from: :digital, to: :print)
    reversible do |dir|
      dir.up do
        execute "UPDATE people SET correspondence = 'print' WHERE confirmed_at IS NULL"
      end
    end
  end
end
