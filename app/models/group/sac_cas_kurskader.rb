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

  class KlassenleitungSelbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KursleitungAspirantSelbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KlassenleitungAspirantSelbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KursleitungUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KlassenleitungUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KursleitungAspirantUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class KlassenleitungAspirantUnselbstaendig < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  roles KursleitungSelbstaendig,
    KlassenleitungSelbstaendig,
    KursleitungAspirantSelbstaendig,
    KlassenleitungAspirantSelbstaendig,
    KursleitungUnselbstaendig,
    KlassenleitungUnselbstaendig,
    KursleitungAspirantUnselbstaendig,
    KlassenleitungAspirantUnselbstaendig
end
