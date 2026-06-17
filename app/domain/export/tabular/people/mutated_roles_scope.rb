# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class MutatedRolesScope
    attr_reader :range, :group, :relevant_role_types

    # group should be a Group::SektionMitglieder or nil for the entire SAC
    def initialize(range, group = nil, relevant_role_types: nil)
      @range = range
      @group = group
      @relevant_role_types = (relevant_role_types || SacCas::MITGLIED_ROLES).map(&:sti_name)
    end

    def roles
      roles_scope.where( # rubocop:disable Rails/WhereNot is not correctly converted
        "person_id NOT IN (?)",
        multiple_roles_in_range.select(:person_id)
      )
    end

    private

    def multiple_roles_in_range
      roles_scope
        .joins("INNER JOIN roles other ON other.person_id = roles.person_id" +
          " AND other.id != roles.id" +
          (group ? " AND other.group_id = roles.group_id" : ""))
        .where(other: {type: relevant_role_types})
    end

    def roles_scope
      scope = Role.unscoped.where(type: relevant_role_types)
      group ? scope.where(group_id: group.id) : scope
    end
  end
end
