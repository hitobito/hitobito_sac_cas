# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigratePraesidiumRoles < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE roles
      SET type = 'Group::SektionsFunktionaere::CoPraesidium', label = ''
      WHERE type = 'Group::SektionsFunktionaere::Praesidium'
        AND label LIKE 'C%'
    SQL

    execute <<~SQL
      UPDATE roles
      SET type = 'Group::SektionsFunktionaere::VizePraesidium', label = ''
      WHERE type = 'Group::SektionsFunktionaere::Praesidium'
        AND label LIKE 'V%'
    SQL

    execute <<~SQL
      UPDATE roles
      SET type = 'Group::SektionsFunktionaere::PraesidiumOrtsgruppe', label = ''
      WHERE type = 'Group::SektionsFunktionaere::Praesidium'
        AND label LIKE '%Unter%'
    SQL
  end

  def down; end
end
