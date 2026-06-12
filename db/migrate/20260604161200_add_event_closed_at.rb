# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddEventClosedAt < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :closed_at, :datetime

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE events
          SET closed_at = updated_at
          WHERE state = 'closed'
        SQL
      end
    end
  end
end
