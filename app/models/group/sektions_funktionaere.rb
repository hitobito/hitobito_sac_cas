# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsFunktionaere < ::Group
  self.static_name = true

  children Group::SektionsVorstand,
    Group::SektionsTourenUndKurse,
    Group::SektionsClubhuetten,
    Group::Sektionshuetten,
    Group::SektionsKommissionen

  self.default_children = [
    Group::SektionsVorstand,
    Group::SektionsTourenUndKurse,
    Group::SektionsKommissionen
  ]

  ### ROLES
  class Praesidium < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Mitgliederverwaltung < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Administration < ::Role
    self.permissions = [:layer_and_below_full]
    self.two_factor_authentication_enforced = true
  end

  class AdministrationReadOnly < ::Role
    self.permissions = [:layer_and_below_read]
    self.two_factor_authentication_enforced = true
  end

  class Kulturbeauftragter < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Finanzen < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Redaktion < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Huettenobmann < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
  end

  class Umweltbeauftragter < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Andere < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  roles Praesidium, Mitgliederverwaltung, Administration,
    AdministrationReadOnly, Finanzen, Redaktion, Huettenobmann,
    Leserecht, Schreibrecht, Andere, Umweltbeauftragter, Kulturbeauftragter
end
