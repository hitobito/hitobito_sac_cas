# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MoveMoreGroupsIntoSektionsfunktionaere < ActiveRecord::Migration[6.1]
  def up
    return unless /mysql/i.match?(connection.adapter_name)

    say_with_time("creating missing default_children of Sektion groups") do
      Group.where(type: "Group::Sektion").find_each do |group|
        group.default_children.each do |group_type|
          next if group.children.where(type: group_type).exists?
          child = group_type.new(name: group_type.label)
          child.parent = group
          child.save!
        end
      end
    end

    # Now that we can be sure that every Sektion has a SektionsFunktionaere subgroup...

    # Move each SektionsTourenkommission group into its sibling SektionsFunktionaere
    execute "UPDATE `groups` AS tourenundkurse SET parent_id=COALESCE((SELECT funktionaere.id FROM (SELECT id, parent_id from `groups` WHERE type = 'Group::SektionsFunktionaere') funktionaere WHERE funktionaere.parent_id = tourenundkurse.parent_id LIMIT 1), tourenundkurse.parent_id) WHERE type='Group::SektionsTourenkommission'"

    # Move each SektionsKommission group into its sibling SektionsFunktionaere
    execute "UPDATE `groups` AS kommissionen SET parent_id=COALESCE((SELECT funktionaere.id FROM (SELECT id, parent_id from `groups` WHERE type = 'Group::SektionsFunktionaere') funktionaere WHERE funktionaere.parent_id = kommissionen.parent_id LIMIT 1), kommissionen.parent_id) WHERE type='Group::SektionsKommission'"

    # Move each SektionsVorstand group into its sibling SektionsFunktionaere
    execute "UPDATE `groups` AS vorstand SET parent_id=COALESCE((SELECT funktionaere.id FROM (SELECT id, parent_id from `groups` WHERE type = 'Group::SektionsFunktionaere') funktionaere WHERE funktionaere.parent_id = vorstand.parent_id LIMIT 1), vorstand.parent_id) WHERE type='Group::SektionsVorstand'"

    # Rebuild the whole group hierarchy
    execute "UPDATE `groups` SET lft=NULL, rgt=NULL"
    old_value = Group.archival_validation
    Group.archival_validation = false
    Group.rebuild!
    Group.archival_validation = old_value

    say_with_time("creating missing default_children of SektionsFunktionaere groups") do
      Group.where(type: "Group::SektionsFunktionaere").find_each do |group|
        group.default_children.each do |group_type|
          next if group.children.where(type: group_type).exists?
          child = group_type.new(name: group_type.label)
          child.parent = group
          child.save!
        end
      end
    end
  end
end
