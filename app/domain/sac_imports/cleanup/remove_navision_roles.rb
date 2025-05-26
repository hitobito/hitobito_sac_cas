# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  class Cleanup::RemoveNavisionRoles
    GROUP_NAME = "Navision Import"

    def run
      obsolete_roles.delete_all.tap do |count|
        puts "Deleted #{count} obsolete #{GROUP_NAME} roles" if count.positive? # rubocop:disable Rails/Output
      end
    end

    private

    def obsolete_roles = navision_roles.where(person_id: other_roles.pluck(:person_id))

    def navision_roles = roles.where(conditions)

    def other_roles = roles.where.not(conditions)

    def conditions = {groups: {type: Group::ExterneKontakte.sti_name, name: GROUP_NAME}}

    def roles = Role.with_inactive.joins(:group)
  end
end
