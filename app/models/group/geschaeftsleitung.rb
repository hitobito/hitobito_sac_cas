# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Geschaeftsleitung < ::Group

  self.static_name = true

  ### ROLES
  class Geschaeftsfuehrung < ::Role
    self.permissions = [:layer_and_below_read, :read_all_people]
    self.two_factor_authentication_enforced = true
  end

  class Ressortleitung < ::Role
    self.permissions = [:layer_and_below_read, :read_all_people]
    self.two_factor_authentication_enforced = true
  end

  class Andere < ::Role
    self.permissions = [:layer_and_below_read, :read_all_people]
    self.two_factor_authentication_enforced = true
  end

  roles Geschaeftsfuehrung, Ressortleitung, Andere

end
