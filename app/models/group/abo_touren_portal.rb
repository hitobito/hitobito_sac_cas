# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::AboTourenPortal < ::Group
  self.static_name = true

  ### ROLES
  class Abonnent < ::Role
    self.permissions = []
    self.basic_permissions_only = true
    self.terminatable = true
  end

  class Neuanmeldung < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Autor < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Community < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Admin < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Andere < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Gratisabonnent < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  roles Abonnent, Neuanmeldung, Admin, Autor, Community, Andere, Gratisabonnent
end
