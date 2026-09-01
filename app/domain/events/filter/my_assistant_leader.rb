# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Filter
  class MyAssistantLeader < Leader
    def leader_roles
      event_types.flat_map(&:role_types).select { |t| role_type_applies?(t) }
    end

    private

    def leader_ids = [Auth.current_person&.id].compact_blank

    def role_type_applies?(role_type)
      role_type.helper? ||
        (role_type.leader? && Events::Filter::MyMainLeader::MAIN_LEADER_ROLES.exclude?(role_type))
    end
  end
end
