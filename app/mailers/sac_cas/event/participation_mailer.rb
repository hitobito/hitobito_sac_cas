# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationMailer
  extend ActiveSupport::Concern

  CONTENT_REJECTED_PARTICIPATION = 'event_participation_rejected'

  def reject(participation)
    @participation = participation
    person = @participation.person

    compose(person, CONTENT_REJECTED_PARTICIPATION)
  end

  private

  def placeholder_event_name
    @participation.event.to_s
  end

  def placeholder_recipient_name_with_salutation
    @participation.person.salutation_value
  end
end
