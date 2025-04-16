# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsTourenUndKurseSommer < Group
  ### ROLES

  class Tourenchef < ::Role
    self.permissions = [:layer_and_below_read, :layer_events_full]
  end

  roles Tourenchef
end
