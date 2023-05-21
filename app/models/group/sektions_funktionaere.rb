# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsFunktionaere < ::Group

  ### ROLES
  class Praesidium < ::Role
    self.permissions = []
  end

  class VizePraesidium < ::Role
    self.permissions = []
  end

  class Funktionaer < ::Role
    self.permissions = []
  end

  class Verwaltung < ::Role
    self.permissions = [:layer_and_below_full]
  end

  class VerwaltungReadOnly < ::Role
    self.permissions = [:layer_and_below_read]
  end

  roles Praesidium, VizePraesidium, Funktionaer, Verwaltung, VerwaltungReadOnly

end
