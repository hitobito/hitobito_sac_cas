# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigrateGroupLanguageFromMountedAttr < ActiveRecord::Migration[8.0]
  def change
    MountedAttribute.where(entry_type: "Group", key: "language").find_each do |mounted_attr|
      group = Group.find_by(id: mounted_attr.entry_id)
      next unless group
      group.update_attribute(:language, mounted_attr.attributes["value"].downcase)
    end

    MountedAttribute.where(entry_type: "Group", key: "language").delete_all
  end
end
