# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::EmailDispatchJob < BaseJob
  self.parameters = [:mailer_method, :tour_id]

  attr_reader :mailer_method, :tour_id

  def initialize(mailer_method, tour_id)
    @mailer_method = mailer_method
    @tour_id = tour_id
  end

  def perform
    set_locale

    if recipients.klass == Event::Participation
      recipients.each do |participation|
        if Event::TourParticipationMailer.respond_to?(mailer_method)
          send_participation_mail(mailer_method, participation)
        else
          send_person_mail(mailer_method, participation.event, participation.person)
        end
      end
    else
      recipients.each do |person|
        send_person_mail(mailer_method, tour, person)
      end
    end
  end

  private

  def send_participation_mail(mailer_method, participation)
    Event::TourParticipationMailer.send(mailer_method, participation).deliver_later
  end

  def send_person_mail(mailer_method, tour, person)
    Event::TourMailer.send(mailer_method, tour, person).deliver_later
  end

  def recipients
    raise "Implement in subclass"
  end

  def tour = @tour ||= Event::Tour.find(tour_id)
end
