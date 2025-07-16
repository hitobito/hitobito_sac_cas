# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class DeleteObsoleteSchreibrechtRoles < ActiveRecord::Migration[7.1]
  def up
   execute <<~SQL
    WITH active_roles AS (
      SELECT roles.id, roles.person_id, roles.type, groups.layer_group_id
      FROM roles
      INNER JOIN groups ON groups.id = roles.group_id
      WHERE (start_on <= CURRENT_DATE OR start_on IS NULL) AND (end_on >= CURRENT_DATE OR end_on IS NULL)
      AND roles.type IN ('Group::SektionsMitglieder::Schreibrecht', 'Group::SektionsTourenUndKurseAllgemein::Tourenchef', 'Group::SektionsTourenUndKurseWinter::Tourenchef', 'Group::SektionsTourenUndKurseSommer::Tourenchef')
    )

    DELETE FROM roles WHERE id IN (
      SELECT DISTINCT active_roles.id
      FROM active_roles
      INNER JOIN active_roles chefs
      ON active_roles.layer_group_id = chefs.layer_group_id AND active_roles.person_id = chefs.person_id
      AND chefs.type IN ('Group::SektionsTourenUndKurseAllgemein::Tourenchef', 'Group::SektionsTourenUndKurseWinter::Tourenchef', 'Group::SektionsTourenUndKurseSommer::Tourenchef')
      WHERE active_roles.type = 'Group::SektionsMitglieder::Schreibrecht'
    )
   SQL
  end
end
