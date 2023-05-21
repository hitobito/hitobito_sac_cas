# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Geschaeftsstelle < ::Group

  ### ROLES
  class Verwaltung < ::Role
    self.permissions = [:layer_and_below_full, :impersonation]
  end

  class VerwaltungReadOnly < ::Role
    self.permissions = [:layer_and_below_read]
  end

  class ITSupport < ::Role
    self.permissions = [:admin, :impersonation]
  end

  roles Verwaltung, VerwaltungReadOnly, ITSupport

end
