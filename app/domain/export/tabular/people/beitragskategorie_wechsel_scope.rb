# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class BeitragskategorieWechselScope < MutatedRolesScope
    def roles
      roles_scope.where(id: relevant_roles.values)
    end

    def relevant_person_ids
      relevant_roles.keys
    end

    private

    def relevant_roles
      roles_scope
        .group_by(&:person_id)
        .select { |person_id, roles| relevant_change?(roles) }
        .transform_values { |roles| roles.last.id }
    end

    def relevant_change?(roles)
      first, last = roles.values_at(0, -1)
      first.beitragskategorie != last.beitragskategorie
    end

    def roles_scope
      super
        .where(start_on: @range)
        .or(super.where(end_on: @range.begin - 1.day..@range.end))
        .order(:start_on)
    end
  end
end
