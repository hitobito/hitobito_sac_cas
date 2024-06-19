# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Wizards::Steps::MembershipTerminatedInfo < Wizards::Step
  # Always return false to avoid save! on the wizard
  def valid?
    false
  end

  def termination_date
    # TODO: Get termination date from membership role of the
    Time.zone.now.to_date
  end
end
