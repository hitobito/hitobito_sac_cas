# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::TourApprovalMailer < ApplicationMailer
  include ::TourMailer

  REQUIRED = "event_tour_approval_required"
  REJECTED = "event_tour_approval_rejected"
  GRANTED = "event_tour_approval_granted"
  SELF_APPROVED = "event_tour_self_approved"

  def required(tour, recipients, cc)
    compose_email(tour, recipients, cc, REQUIRED)
  end

  def rejected(tour, recipients, cc)
    compose_email(tour, recipients, cc, REJECTED)
  end

  def granted(tour, recipients, cc)
    compose_email(tour, recipients, cc, GRANTED)
  end

  def self_approved(tour, recipients, cc)
    compose_email(tour, recipients, cc, SELF_APPROVED)
  end

  private

  def compose_email(tour, recipients, cc, content_key)
    headers[:cc] = Array(cc).flatten.compact.map(&:email)

    @people = Array(recipients).flatten
    @event = tour
    @group = @context = tour.groups.first

    I18n.with_locale(@group.language) do
      compose(@people, content_key, context: @context)
    end
  end
end
