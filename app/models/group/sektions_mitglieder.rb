# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsMitglieder < ::Group

  self.static_name = true

  ### ROLES
  class Mitglied < ::Role
    include ::SacCas::RoleBeitragskategorie

    self.permissions = []
    self.basic_permissions_only = true
  end

  class Abonnement < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Ehrenmitglied < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Beguenstigt < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end


  roles Mitglied, Abonnement,
    Ehrenmitglied, Beguenstigt

end
