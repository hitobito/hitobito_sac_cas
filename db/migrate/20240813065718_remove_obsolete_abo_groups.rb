# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class RemoveObsoleteAboGroups < ActiveRecord::Migration[6.1]
  def up
    execute "DELETE FROM roles WHERE type = 'Group::AboMagazin::Autor'"
    execute "DELETE FROM groups WHERE type = 'Group::Abonnenten'"
  end
end
