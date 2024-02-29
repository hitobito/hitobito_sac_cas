# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration
  class AboTourenPortal < Base
    self.shared_partial = :abo_infos
    self.main_person_class = SelfRegistration::Abo::MainPerson

    def dummy_costs
      [OpenStruct.new(amount: 45)]
    end
  end
end
