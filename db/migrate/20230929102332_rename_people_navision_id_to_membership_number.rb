# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RenamePeopleNavisionIdToMembershipNumber < ActiveRecord::Migration[6.1]

  def up
    rename_column :people, :navision_id, :membership_number
    execute "ALTER TABLE people ALTER COLUMN membership_number TYPE integer USING (membership_number::integer)"
  end

  def down
    rename_column :people, :membership_number, :navision_id
    change_column :people, :navision_id, :string
  end
end
