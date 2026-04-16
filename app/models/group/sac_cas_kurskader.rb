# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SacCasKurskader < ::Group
  self.static_name = true

  ### ROLES
  class KursleitungSelbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KlassenlehrerSelbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KursleitungAspirantSelbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KlassenlehrerAspirantSelbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KursleitungUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KlassenlehrerUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KursleitungAspirantUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KlassenlehrerAspirantUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  roles KursleitungSelbstaendig,
    KlassenlehrerSelbstaendig,
    KursleitungAspirantSelbstaendig,
    KlassenlehrerAspirantSelbstaendig,
    KursleitungUnselbstaendig,
    KlassenlehrerUnselbstaendig,
    KursleitungAspirantUnselbstaendig,
    KlassenlehrerAspirantUnselbstaendig
end
