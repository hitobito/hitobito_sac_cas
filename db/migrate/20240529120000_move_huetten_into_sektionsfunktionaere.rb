# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MoveHuettenIntoSektionsfunktionaere < ActiveRecord::Migration[6.1]
  def up
    return unless connection.adapter_name =~ /mysql/i

    # Move each SektionsHuettenkommission group into its sibling SektionsFunktionaere
    execute "UPDATE groups AS huetten SET parent_id=(SELECT funktionaere.id FROM (SELECT id, parent_id from groups WHERE type = 'Group::SektionsFunktionaere') funktionaere WHERE funktionaere.parent_id = huetten.parent_id LIMIT 1) WHERE type='Group::SektionsHuettenkommission'"

    # Rebuild the whole group hierarchy
    execute "UPDATE groups SET lft=NULL, rgt=NULL"
    old_value = Group.archival_validation
    Group.archival_validation = false
    Group.rebuild!
    Group.archival_validation = old_value

  end
end
