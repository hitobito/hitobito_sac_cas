# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class JubilareRow < Export::Tabular::Row
    include CommonSektionPersonRowBehaviour

    private

    def membership_role
      @membership_role ||= active_role_in_group(*SacCas::MITGLIED_ROLES)
    end
  end
end
