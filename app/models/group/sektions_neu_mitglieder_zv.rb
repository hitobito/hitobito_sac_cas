# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsNeuMitgliederZv < ::Group
  ### ROLES
  class Neuanmeldung < ::Role
    self.permissions = []
    self.basic_permissions_only = true
  end

  class Einzel < Neuanmeldung; end
  class Jugend < Neuanmeldung; end
  class Familie < Neuanmeldung; end

  roles Einzel, Jugend, Familie
end
