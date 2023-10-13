# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Geschaeftsstelle < ::Group

  ### ROLES
  class Mitgliederdienst < ::Role
    self.permissions = [:layer_and_below_full, :impersonation]
  end

  class Kursorganisation < ::Role
    self.permissions = [:layer_full, :layer_and_below_read, :impersonation]
  end

  class Fundraising < ::Role
    self.permissions = [:layer_and_below_read]
  end

  class Kommunikation < ::Role
    self.permissions = [:layer_full, :layer_and_below_read]
  end

  class Rechnungswesen < ::Role
    self.permissions = [:layer_full, :layer_and_below_read]
  end

  class Leistungssport < ::Role
    self.permissions = [:layer_and_below_read]
  end

  class HuettenUmwelt < ::Role
    self.permissions = [:layer_and_below_full]
  end

  class ITSupport < ::Role
    self.permissions = [:layer_and_below_full, :admin, :impersonation]
  end

  roles Mitgliederdienst, Kursorganisation, Fundraising, Kommunikation,
        Rechnungswesen, Leistungssport, HuettenUmwelt, ITSupport

end
