# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ConvertCanceledReasonToStringEnum < ActiveRecord::Migration[8.0]
  def up
    change_column :events, :canceled_reason, :string

    execute <<-SQL
      UPDATE events
      SET canceled_reason = CASE
        WHEN canceled_reason = '0' THEN 'minimum_participants'
        WHEN canceled_reason = '1' THEN 'no_leader'
        WHEN canceled_reason = '2' THEN 'weather'
        ELSE canceled_reason
      END
    SQL
  end

  def down
    change_column :events, :canceled_reason, :integer, default: 0
  end
end
