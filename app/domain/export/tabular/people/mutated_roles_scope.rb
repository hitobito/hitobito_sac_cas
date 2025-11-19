# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class MutatedRolesScope
    def initialize(group, range)
      @group = group
      @range = range
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
        .joins("INNER JOIN roles other ON other.person_id = roles.person_id " \
          "AND other.group_id = roles.group_id")
        .where(other: {type: relevant_role_types})
    end

    def roles_scope
      Role.unscoped.where(
        group_id: @group.id,
        type: relevant_role_types
      )
    end

    def relevant_role_types
      SacCas::MITGLIED_ROLES.map(&:sti_name)
    end
  end
end
