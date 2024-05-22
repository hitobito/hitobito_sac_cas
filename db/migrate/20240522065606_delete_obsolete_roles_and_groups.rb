# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class DeleteObsoleteRolesAndGroups < ActiveRecord::Migration[6.1]
  def up
    return unless connection.adapter_name =~ /mysql/i

    execute "DELETE FROM roles WHERE type='Group::SektionsFuntionaere::Umweltbeauftragte'"
    execute "DELETE FROM roles WHERE type='Group::SektionsFuntionaere::Kulturbeauftragte'"

    execute <<~SQL
      DELETE groups FROM groups
      INNER JOIN groups g1 ON groups.layer_group_id = g1.id AND g1.type = 'Group::SacCas'
      AND groups.type = 'Group::ExterneKontakte'
    SQL

    execute <<~SQL
      DELETE roles FROM roles
      LEFT JOIN groups ON roles.group_id = groups.id
      WHERE groups.id IS NULL
    SQL
  end
end
