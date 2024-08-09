# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::AboMagazine < ::Group
  self.static_name = true

  ### ROLES
  class Autor < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Andere < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Uebersetzer < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  children Group::AboMagazin
  roles Autor, Andere, Uebersetzer
end
