# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsHuettenkommission < ::Group
  self.static_name = true

  children Group::SektionsHuette

  ### ROLES
  class Huettenobmann < ::Role
    self.permissions = [:group_and_below_read]
    self.two_factor_authentication_enforced = true
  end

  class Andere < ::Role
    self.permissions = [:group_read]
    self.basic_permissions_only = true
  end

  roles Huettenobmann, Andere
end
