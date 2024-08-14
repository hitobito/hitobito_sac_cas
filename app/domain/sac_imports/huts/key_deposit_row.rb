# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class KeyDepositRow < RoleRow
    include RemovingPlaceholderContactRole

    self.code = 4011
    self.role = "Andere"
    self.role_label = "schluesseldepot"

    def import!
      super do
        remove_placeholder_contact_role(person)
      end
    end
  end
end
