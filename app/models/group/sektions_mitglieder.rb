# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsMitglieder < ::Group

  ### ROLES
  class Mitglied < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Einzel < Mitglied; end
  class Jugend < Mitglied; end
  class Familie < Mitglied; end
  class FreiKind < Mitglied; end
  class FreiFam < Mitglied; end
  class Abonnement < Mitglied; end
  class Geschenkmitgliedschaft < Mitglied; end
  class Ehrenmitglied < Mitglied; end
  class Beguenstigt < Mitglied; end

  roles Einzel, Jugend, Familie,
    FreiKind, FreiFam,
    Abonnement, Geschenkmitgliedschaft,
    Ehrenmitglied, Beguenstigt

end
