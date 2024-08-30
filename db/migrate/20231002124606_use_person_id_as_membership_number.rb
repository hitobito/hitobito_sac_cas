# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class UsePersonIdAsMembershipNumber < ActiveRecord::Migration[6.1]
  def up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<-SQL
        SELECT setval(pg_get_serial_sequence('people', 'id'), #{MIN_GENERATED_MEMBERSHIP_NUMBER}, false);
      SQL
    end

    remove_column :people, :membership_number
  end

  def down
    add_column :people, :membership_number, :integer
  end

  private

  MIN_GENERATED_MEMBERSHIP_NUMBER = 600_000

end
