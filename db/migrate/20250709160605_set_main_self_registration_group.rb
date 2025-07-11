# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SetMainSelfRegistrationGroup < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE groups SET main_self_registration_group = true WHERE id IN
            (SELECT id FROM groups WHERE type = 'Group::AboBasicLogin' LIMIT 1);
        SQL
      end
      dir.down do
        execute "UPDATE groups SET main_self_registration_group = false WHERE type = 'Group::AboBasicLogin'"
      end
    end
  end
end
