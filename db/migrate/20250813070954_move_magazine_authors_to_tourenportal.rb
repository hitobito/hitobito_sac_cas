# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MoveMagazineAuthorsToTourenportal < ActiveRecord::Migration[7.1]
  def up
    change_roles(from: Group::AboMagazine::Autor, to: Group::AboTourenPortal::Autor)
  end

  private

  def change_roles(from:, to:)
    execute <<~SQL
      WITH
        source AS (SELECT id FROM groups WHERE groups.type = '#{from.to_s.deconstantize}'),
        target AS (SELECT id FROM groups WHERE groups.type = '#{to.to_s.deconstantize}')

      UPDATE people
        SET primary_group_id = (SELECT id FROM target)
        FROM roles
        WHERE
          people.id = roles.person_id AND
          roles.type = '#{from}' AND
          people.primary_group_id = (SELECT id FROM source);

      WITH
        source AS (SELECT id FROM groups WHERE groups.type = '#{from.to_s.deconstantize}'),
        target AS (SELECT id FROM groups WHERE groups.type = '#{to.to_s.deconstantize}')

      UPDATE roles
        SET type = '#{to}', group_id = (SELECT id FROM target)
        WHERE
          roles.type = '#{from}';
    SQL
  end
end
