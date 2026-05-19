# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ParticipantsEmailDispatchJob < Event::Tour::EmailDispatchJob
  self.parameters += [:states]
  attr_reader :states

  def initialize(mailer_method, tour_id, states)
    super(mailer_method, tour_id)
    @states = states
  end

  private

  def recipients
    participant_types = tour.role_types.select(&:participant?).map(&:sti_name)

    tour.participations
      .joins(:roles)
      .where(event_roles: {type: participant_types})
      .where(state: states)
  end
end
