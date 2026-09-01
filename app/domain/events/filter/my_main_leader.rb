# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Filter
  class MyMainLeader < Leader
    MAIN_LEADER_ROLES = [
      Event::Role::Leader,
      Event::Course::Role::Leader
    ]

    def leader_roles
      super & MAIN_LEADER_ROLES
    end

    private

    def leader_ids = [Auth.current_person&.id].compact_blank
  end
end
