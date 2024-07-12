# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class UpdateGroupStructure < ActiveRecord::Migration[6.1]
  def up
    return unless connection.adapter_name =~ /mysql/i

    say_with_time("deleting groups of outdated types") do
      Group.where(type: ["Group::SektionsExterneKontakte", "Group::SektionsHuettenkommission", "Group::SektionsHuette", "Group::SektionsKommission", "Group::SektionsTourenkommission"]).find_each do |group|
        hard_destroy_group(group)
      end
    end

    say_with_time("deleting any people filters referencing the outdated group types") do
      PeopleFilter.where("filter_chain LIKE "%Group::SektionsExterneKontakte%"").
        or(PeopleFilter.where("filter_chain LIKE "%Group::SektionsHuettenkommission%"")).
        or(PeopleFilter.where("filter_chain LIKE "%Group::SektionsHuette%"")).
        or(PeopleFilter.where("filter_chain LIKE "%Group::SektionsKommission%"")).
        or(PeopleFilter.where("filter_chain LIKE "%Group::SektionsTourenkommission%"")).
        to_a.
        map(&:destroy!)
    end

    say_with_time("creating missing default_children of Sektion and Ortsgruppe groups") do
      Group.where(type: ["Group::Sektion", "Group::Ortsgruppe"]).find_each do |group|
        group.default_children.each do |group_type|
          next if group.children.where(type: group_type).exists?
          child = group_type.new(name: group_type.label)
          child.parent = group
          child.save!
        end
      end
    end
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

  def hard_destroy_group(group)
    # load relations which are not declared on the group model, to destroy all orphaned later
    relations = [
      Person::AddRequest::IgnoredApprover,
      BackgroundJobLogEntry,
      SacSectionMembershipConfig,
    ]
    related = relations.flat_map { |clazz| clazz.where(group_id: group.id).to_a }

    group.really_destroy!

    related.each do |related_model|
      related_model.destroy
    rescue RecordNotFound
      # ignore, must have already been deleted
    end
  end
end
