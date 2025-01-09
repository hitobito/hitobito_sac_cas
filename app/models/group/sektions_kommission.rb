# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsKommission < ::Group
  ### ROLES
  class Leserecht < ::Role
    self.permissions = [:group_read]
    self.two_factor_authentication_enforced = true
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_full]
    self.two_factor_authentication_enforced = true
  end

  class Mitglied < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Praesidium < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Andere < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  roles Leserecht, Schreibrecht, Mitglied, Praesidium, Andere
end
