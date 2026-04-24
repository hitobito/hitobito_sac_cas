# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::TourParticipationMailer < ApplicationMailer
  include TourMailer

  APPLIED = "event_tour_application_confirmation_applied"
  UNCONFIRMED = "event_tour_application_confirmation_unconfirmed"
  ASSIGNED = "event_tour_application_confirmation_assigned"
  REJECT_PARTICIPATION = "event_tour_participation_reject"
  SUMMONED_PARTICIPATION = "event_tour_participation_summon"
  CANCELED_PARTICIPATION = "event_tour_participation_canceled"

  def confirmation(participation, content_key)
    compose_email(participation, content_key)
  end

  def reject(participation)
    compose_email(participation, REJECT_PARTICIPATION)
  end

  def summon(participation)
    compose_email(participation, SUMMONED_PARTICIPATION)
  end

  def canceled(participation)
    compose_email(participation, CANCELED_PARTICIPATION)
  end

  private

  def compose_email(participation, content_key)
    @participation = participation
    @event = participation.event
    @person = participation.person
    @group = @context = @event.groups.first # @context is required for mailer layout

    I18n.with_locale(@group.language) do
      compose(@person, content_key, context: @context)
    end
  end
end
