# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::AboTourenPortal < SelfRegistration::AboBasicLogin
  self.partials = [:main_email, :emailless_main_person]
  self.shared_partial = :abo_infos

  def dummy_costs
    [OpenStruct.new(amount: 45)]
  end
end
