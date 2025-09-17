# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class ChangeZusatzsektionToFamilyAbility < AbilityDsl::Base
    include Memberships::Constraints

    on(Memberships::ChangeZusatzsektionToFamily) do
      class_side(:manage).if_backoffice?
    end
  end
end
