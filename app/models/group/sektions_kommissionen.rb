# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsKommissionen < ::Group
  self.static_name = true

  ### ROLES
  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
  end

  children Group::SektionsKommissionHuetten,
    Group::SektionsKommissionTouren,
    Group::SektionsKommissionUmweltUndKultur,
    Group::SektionsKommission

  roles Leserecht, Schreibrecht
end
