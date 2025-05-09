# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsKommissionTouren < ::Group
  ### ROLES
  class Mitglied < ::Role
    self.permissions = [:group_read, :layer_events_full]
  end

  class Praesidium < ::Role
    self.permissions = [:group_read, :layer_events_full]
  end

  class Andere < ::Role
    self.permissions = [:group_read]
  end

  roles Mitglied, Praesidium, Andere
end
