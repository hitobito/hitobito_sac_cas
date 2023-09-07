# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Huette < ::Group

  self.layer = true

  ### ROLES
  class Huettenwart < ::Role
    self.permissions = [:group_full]
  end

  class HuettenwartsPartner < ::Role
    self.permissions = [:group_full]
  end

  class Huettenchef < ::Role
    self.permissions = [:group_full]
  end

  class Mitarbeiter < ::Role
    self.permissions = []
  end

  class Schluesseldepot < ::Role
    self.permissions = []
  end

  class Funktionaer < ::Role
    self.permissions = []
  end

  roles Huettenwart,
    HuettenwartsPartner,
    Huettenchef,
    Mitarbeiter,
    Schluesseldepot,
    Funktionaer

end
