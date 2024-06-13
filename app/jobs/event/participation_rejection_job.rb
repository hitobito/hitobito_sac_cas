# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
class Event::ParticipationRejectionJob < BaseJob
  self.parameters = [:participation_id]

  def initialize(participation)
    super()
    @participation_id = participation.id
  end

  def perform
    return unless participation # may have been deleted again

    set_locale
    send_rejection
  end

  private

  def send_rejection
    Event::ParticipationMailer.reject(participation).deliver_now
  end

  def participation
    @participation ||= Event::Participation.find_by(id: @participation_id)
  end
end
