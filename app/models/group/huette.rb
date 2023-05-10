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

  class HuettenObmann < ::Role
    self.permissions = []
  end

  class Mitarbeitende < ::Role
    self.permissions = []
  end

  class Huettenbetreuer < ::Role
    self.permissions = []
  end

  roles Huettenwart, HuettenwartsPartner, HuettenObmann, Mitarbeitende, Huettenbetreuer

end
