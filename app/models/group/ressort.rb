# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Ressort < ::Group

  ### ROLES
  class Leitung < ::Role
    self.permissions = [:group_full]
  end

  class Mitarbeitende < ::Role
    self.permissions = []
  end

  class Rechnungswesen < ::Role
    self.permissions = [:layer_and_below_full, :finance]
  end

  class Mitgliederverwaltung < ::Role
    self.permissions = [:layer_and_below_full]
  end

  class Kursverwaltung < ::Role
    self.permissions = [:layer_and_below_full]
  end

  class ITSupport < ::Role
    self.permissions = [:layer_and_below_full, :admin]
  end

  roles Leitung, Mitarbeitende, Rechnungswesen, Mitgliederverwaltung, Kursverwaltung, ITSupport

end
