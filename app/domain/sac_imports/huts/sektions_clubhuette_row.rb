# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class SektionsClubhuetteRow < HutRow
    self.type = "SektionsClubhuette"
    self.category = "SAC Clubhütte"
    self.owned_by_geschaeftsstelle = false
  end
end
