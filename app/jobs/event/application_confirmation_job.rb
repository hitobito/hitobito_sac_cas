# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::ApplicationConfirmationJob < BaseJob
  self.parameters = %i[content_key participation_id]

  def initialize(participation, content_key)
    super()
    @content_key = content_key
    @participation_id = participation.id
  end

  def perform
    return unless participation # may have been deleted again

    Event::ApplicationConfirmationMailer.confirmation(participation, @content_key).deliver_now
  end

  private

  def participation
    @participation ||= Event::Participation.find_by(id: @participation_id)
  end
end
