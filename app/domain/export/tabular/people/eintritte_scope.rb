# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class EintritteScope < MutatedRolesScope
    def first_roles_by_person
      rownum = "ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_on ASC) AS rownum"
      ranked = Role.unscoped.from(roles.select(:id, rownum)).where("rownum = 1")
      Role.unscoped.where("roles.id IN (?)", ranked.select(:id)) # rubocop:disable Rails/WhereEquals
    end

    private

    def multiple_roles_in_range
      super
        .where("other.start_on < :begin", begin: @range.begin)
        .where("other.end_on >= :begin OR " \
          "(other.end_on = :day_before AND roles.start_on = :begin)",
          begin: @range.begin,
          day_before: @range.begin - 1.day)
    end

    def roles_scope
      super.where(start_on: @range)
    end
  end
end
