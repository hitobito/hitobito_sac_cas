# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::TourMailer < ApplicationMailer
  include ::TourMailer
  include MultilingualMailer

  PUBLICATION = "event_tour_publication"
  PUBLICATION_SUBITO = "event_tour_publication_subito"
  PARTICIPATION_SUMMON = "event_tour_participation_summon"
  PARTICIPATION_REJECT = "event_tour_participation_reject"
  BACK_TO_DRAFT = "event_tour_back_to_draft"
  BACK_TO_APPROVED = "event_tour_back_to_approved"
  BACK_TO_PUBLISHED = "event_tour_back_to_published"
  BACK_TO_READY = "event_tour_back_to_ready"

  def publication(tour, recipient)
    compose_email(tour, recipient, PUBLICATION)
  end

  def publication_subito(tour, recipient)
    compose_email(tour, recipient, PUBLICATION_SUBITO)
  end

  def participation_summon(tour, recipient)
    compose_email(tour, recipient, PARTICIPATION_SUMMON)
  end

  def participation_reject(tour, recipient)
    compose_email(tour, recipient, PARTICIPATION_REJECT)
  end

  def back_to_draft(tour, recipient)
    compose_email(tour, recipient, BACK_TO_DRAFT)
  end

  def back_to_approved(tour, recipient)
    compose_email(tour, recipient, BACK_TO_APPROVED)
  end

  def back_to_published(tour, recipient)
    compose_email(tour, recipient, BACK_TO_PUBLISHED)
  end

  def back_to_ready(tour, recipient)
    compose_email(tour, recipient, BACK_TO_READY)
  end

  # The following emails are tour participation emails
  # These can also be sent to people without an ongoing participation
  # To keep the method parameters for the participation mailer the same
  # for all mailer methods, we have implemented these emails here too.

  def closing(tour, recipient)
    compose_email(tour, recipient, Event::TourParticipationMailer::CLOSING)
  end

  def canceled_minimum_participants(tour, recipient)
    compose_email(tour, recipient, Event::TourParticipationMailer::CANCELED_MINIMUM_PARTICIPANTS)
  end

  def canceled_no_leader(tour, recipient)
    compose_email(tour, recipient, Event::TourParticipationMailer::CANCELED_NO_LEADER)
  end

  def canceled_weather(tour, recipient)
    compose_email(tour, recipient, Event::TourParticipationMailer::CANCELED_WEATHER)
  end

  private

  def compose_email(tour, recipient, content_key)
    @person = recipient
    @event = tour
    @group = @context = tour.groups.first

    compose(recipient, content_key, context: @context)
  end
end
