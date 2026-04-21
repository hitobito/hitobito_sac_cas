#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RemoveDurationHFromEvents < ActiveRecord::Migration[8.0]
  def change
    remove_column :events, :duration_h
    rename_column :events, :duration_m, :duration

    Event.reset_column_information
  end
end
