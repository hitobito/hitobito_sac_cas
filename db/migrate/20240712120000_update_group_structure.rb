# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class UpdateGroupStructure < ActiveRecord::Migration[6.1]
  def up
    outdated_group_ids = Group.where(type: ["Group::SektionsExterneKontakte", "Group::SektionsHuettenkommission", "Group::SektionsHuette", "Group::SektionsKommission", "Group::SektionsTourenkommission"]).pluck(:id)
    force_delete_role_types = ["Group::SektionsHuette::Huettenchef"]

    say_with_time("deleting groups and roles of outdated types") do
      if outdated_group_ids.present?
        # We need to overwrite the type column, because the outdated value in it will otherwise confuse Rails
        execute("UPDATE groups SET type='Group', name='temp' WHERE id IN (#{outdated_group_ids.join(', ')})")
        # Some roles already have to be deleted, otherwise they'll cause problems later
        execute("DELETE FROM roles WHERE group_id IN (#{outdated_group_ids.join(', ')})")
      end
      execute("DELETE FROM roles WHERE type IN ('#{force_delete_role_types.join('\', \'')}')")

      outdated_group_ids.each do |id|
        hard_destroy_group(id)
      end
    end

    say_with_time("deleting any people filters referencing the outdated group types") do
      PeopleFilter.where("filter_chain LIKE '%Group::SektionsExterneKontakte%'").
        or(PeopleFilter.where("filter_chain LIKE '%Group::SektionsHuettenkommission%'")).
        or(PeopleFilter.where("filter_chain LIKE '%Group::SektionsHuette%'")).
        or(PeopleFilter.where("filter_chain LIKE '%Group::SektionsKommission%'")).
        or(PeopleFilter.where("filter_chain LIKE '%Group::SektionsTourenkommission%'")).
        to_a.
        map(&:destroy!)
    end

    say_with_time("creating missing default_children of Sektion and Ortsgruppe groups") do
      Group.where(type: ["Group::Sektion", "Group::Ortsgruppe"]).find_each do |group|
        group.default_children.each do |group_type|
          next if group.children.where(type: group_type.sti_name).exists?
          group_type.create(name: group_type.label, parent: group)
        end
      end
    end
    say_with_time("creating missing default_children of SektionsFunktionaere groups") do
      Group.where(type: "Group::SektionsFunktionaere").find_each do |group|
        group.default_children.each do |group_type|
          next if group.children.where(type: group_type.sti_name).exists?
          group_type.create(name: group_type.label, parent: group)
        end
      end
    end
    say_with_time("one-time creation of some commissions in all sections") do
      Group.where(type: "Group::SektionsKommissionen").find_each do |group|
        ["Group::SektionsKommissionTouren", "Group::SektionsKommissionUmweltUndKultur"].each do |group_type|
          next if group.children.where(type: group_type).exists?
          next unless Object.const_defined? group_type
          type = Object.const_get(group_type)
          type.create(name: type.label, parent: group)
        end
      end
    end
    say_with_time("one-time creation of some touren und kurse groups in all sections") do
      Group.where(type: "Group::SektionsTourenUndKurse").find_each do |group|
        ["Group::SektionsTourenUndKurseSommer", "Group::SektionsTourenUndKurseWinter"].each do |group_type|
          next if group.children.where(type: group_type).exists?
          next unless Object.const_defined? group_type
          type = Object.const_get(group_type)
          type.create(name: type.label, parent: group)
        end
      end
    end

    say_with_time("apply the effects of some Role#after_destroy callbacks which might have been circumvented (may take up to an hour!)") do
      connection = ActiveRecord::Base.connection
      sql = <<-SQL
        SELECT * FROM people
      SQL
      people = connection.execute(sql)

      for person in people do
        role = person.roles.first
        next unless role

        # Role#reset_contact_data_visible
        contact_data = person.roles.collect(&:permissions).flatten.include?(:contact_data)
        person.update_column :contact_data_visible, contact_data

        # Role#reset_primary_group
        person.update_column :primary_group_id, person.roles.order(updated_at: :desc).first.try(:group_id)
      end
    end
  end

  def hard_destroy_group(group_id)
    # load relations which are not declared on the group model, to destroy all orphaned later
    relations = [
      Person::AddRequest::IgnoredApprover,
      BackgroundJobLogEntry,
      SacSectionMembershipConfig,
    ]
    related = relations.flat_map { |clazz| clazz.where(group_id: group_id).to_a }

    # We first have to delete all roles in these groups without callbacks, because we will get stuck
    # trying to load some outdated group or role type in some callback otherwise
    Role.where(group_id: group_id).delete_all

    Group.find(group_id).really_destroy!

    related.each do |related_model|
      related_model.destroy
    rescue RecordNotFound
      # ignore, must have already been deleted
    end
  end
end
