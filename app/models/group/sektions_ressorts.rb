# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsRessorts < ::Group
  ### ROLES
  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
    self.two_factor_authentication_enforced = true
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
    self.two_factor_authentication_enforced = true
  end

  children Group::SektionsRessorts, Group::SektionsRessort

  roles Leserecht, Schreibrecht
end
