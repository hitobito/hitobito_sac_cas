# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsVorstand < ::Group
  ### ROLES
  class Praesidium < ::Role
    self.permissions = [:group_read]
  end

  class Mitglied < ::Role
    self.permissions = [:group_read]
  end

  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
    self.two_factor_authentication_enforced = true
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
    self.two_factor_authentication_enforced = true
  end

  class Andere < ::Role
    self.permissions = [:group_read]
  end

  roles Praesidium, Mitglied, Leserecht, Schreibrecht, Andere
end
