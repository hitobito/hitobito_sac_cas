# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Kommission < ::Group
  ### ROLES
  class Praesidium < ::Role
    self.permissions = []
  end

  class Mitglied < ::Role
    self.permissions = []
  end

  class Andere < ::Role
    self.permissions = []
  end

  children Group::Kommission

  roles Praesidium, Mitglied, Andere
end
