# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class SwitchStammsektionAbility < AbilityDsl::Base
    include Memberships::Constraints

    on(Wizards::Memberships::SwitchStammsektion) do
      permission(:any).may(:create).backoffice_and_no_data_quality_issue
    end
  end
end
