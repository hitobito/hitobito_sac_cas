# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class DeleteObsoleteRolesAndGroups < ActiveRecord::Migration[6.1]
  def up
    execute "DELETE FROM roles WHERE type='Group::SektionsFunktionaere::Umweltbeauftragte'"
    execute "DELETE FROM roles WHERE type='Group::SektionsFunktionaere::Kulturbeauftragte'"

    execute <<~SQL
      DELETE FROM groups
        USING groups AS g1
        WHERE groups.layer_group_id = g1.id
        AND g1.type = 'Group::SacCas'
        AND groups.type = 'Group::ExterneKontakte';
    SQL

    execute <<~SQL
      DELETE FROM roles
      USING groups
      WHERE roles.group_id = groups.id
      AND groups.id IS NULL;
    SQL
  end
end
