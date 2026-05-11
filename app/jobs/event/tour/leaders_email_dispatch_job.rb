# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito__sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::LeadersEmailDispatchJob < Event::Tour::EmailDispatchJob
  private

  def recipients
    leader_types = tour.role_types.select(&:leader?).map(&:sti_name)

    tour.participations
      .joins(:roles)
      .where(event_roles: {type: leader_types})
  end
end
