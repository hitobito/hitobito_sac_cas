# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::SacStatistics
  class SektionZusatzmitgliederSheet < SektionMitgliederSheet
    def relevant_role_types
      SacCas::MITGLIED_ZUSATZSEKTION_ROLES
    end
  end
end
