# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigrateRoleStartOnForKaiseregg< ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE roles
      SET start_on = '1977-06-10'
      WHERE group_id = 6395
        AND start_on = '1978-01-12'
    SQL
  end
end
