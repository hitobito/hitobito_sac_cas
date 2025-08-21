# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Export::Pdf::Participations::KeyDataSheet::LeaderRoles
  def highest_leader_role_type(roles)
    @highest_leader_role_type ||= Event::Course::LEADER_ROLES.find do |type|
      roles.any? { |role| role.type == type }
    end.demodulize.underscore
  end
end
