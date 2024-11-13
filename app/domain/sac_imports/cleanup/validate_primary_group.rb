# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  class Cleanup::ValidatePrimaryGroup
    OUTER_JOIN = "LEFT OUTER JOIN roles ON roles.person_id = people.id AND roles.group_id = primary_group_id"

    def run
      nullify_primary_group if people_without_roles.exists?
      reset_primary_group if people_without_primary_group.exists?
    end

    private

    def nullify_primary_group
      puts "Nullifying primary_group_id for #{people_without_roles.count} People without roles" # rubocop:disable Rails/Output
      people_without_roles.update_all(primary_group_id: nil)
    end

    def reset_primary_group
      puts "Resetting primary_group_id for #{people_without_primary_group.count} People" # rubocop:disable Rails/Output
      people_without_primary_group.find_each do |person|
        ::People::UpdateAfterRoleChange.new(person.reload).set_first_primary_group
      end
    end

    def people_without_roles = people.where.missing(:roles)

    def people_without_active_roles = people.merge(Role.active).joins(OUTER_JOIN).where(roles: {group_id: nil})

    def people_without_primary_group = people.merge(Role.active).joins(OUTER_JOIN).where(roles: {group_id: nil})

    def people = Person.where.not(id: Person.root.id).where.not(primary_group_id: nil)
  end
end
