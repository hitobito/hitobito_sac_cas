# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Geschaeftsstelle < ::Group

  ### ROLES
  class Mitarbeiter < ::Role
    self.permissions = [:layer_and_below_full]
    self.two_factor_authentication_enforced = true
  end

  class MitarbeiterLesend < ::Role
    self.permissions = [:layer_and_below_read]
    self.two_factor_authentication_enforced = true
  end

  class Admin < ::Role
    self.permissions = [:layer_and_below_full, :admin, :impersonation]
    self.two_factor_authentication_enforced = true
  end

  roles Mitarbeiter, MitarbeiterLesend, Admin

end
