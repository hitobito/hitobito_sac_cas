# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsVorstand < ::Group

  ### ROLES
  class Praesident < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class VizePraesident < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class Vorstandsmitglied < ::Role
    self.permissions = [:layer_read, :contact_data]
  end

  class Kassier < ::Role
    self.permissions = [:layer_and_below_full, :contact_data, :finance]
  end

  class Mitgliederverwaltung < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  roles Praesident, VizePraesident, Vorstandsmitglied, Kassier, Mitgliederverwaltung

end
