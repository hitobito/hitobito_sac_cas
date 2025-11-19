# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class AustritteScope < MutatedRolesScope
    private

    def multiple_roles_in_range
      super
        .where("other.end_on > :end", end: @range.end)
        .where("other.start_on <= :end OR " \
          "(other.start_on = :day_after AND roles.end_on = :end)",
          end: @range.end,
          day_after: @range.end + 1.day)
    end

    def roles_scope
      super.where(end_on: @range)
    end
  end
end
