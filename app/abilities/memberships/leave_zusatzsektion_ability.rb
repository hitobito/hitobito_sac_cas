# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class LeaveZusatzsektionAbility < AbilityDsl::Base
    include Memberships::Constraints

    on(Wizards::Memberships::LeaveZusatzsektion) do
      permission(:any).may(:create).for_self_if_active_member_or_backoffice
    end
  end
end
