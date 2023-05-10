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

  class Ehrenmitglied < Mitglied; end
  class Beguenstigt < Mitglied; end
  class Interessent < Mitglied; end

  roles Mitglied, Ehrenmitglied, Beguenstigt, Interessent

end
