# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class HutChairmanRow < RoleRow
    include RemovingPlaceholderContactRole

    self.code = 4007
    self.role = "Huettenobmann"

    def import!
      super do
        remove_placeholder_contact_role(person)
      end
    end

    private

    def group
      Group.find_by(navision_id: contact_navision_id)
        .descendants
        .find { |child| child.type == "Group::SektionsFunktionaere" }
    end
  end
end
