# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationConfirmationJob
  extend ActiveSupport::Concern

  private

  def send_confirmation
    case @participation.event
    when Event::Course
      send_confirmation_for_course
    when Event::Tour
      send_confirmation_for_tour
    else
      super
    end
  end

  def send_confirmation_for_course
    Event::CourseParticipationMailer
      .confirmation(participation, course_confirmation_content_key)
      .deliver_later
  end

  def course_confirmation_content_key
    if participation.state == "assigned"
      Event::CourseParticipationMailer::ASSIGNED
    elsif participation.state == "unconfirmed"
      Event::CourseParticipationMailer::UNCONFIRMED
    else
      Event::CourseParticipationMailer::APPLIED
    end
  end

  def send_confirmation_for_tour
    Event::TourParticipationMailer
      .confirmation(participation, tour_confirmation_content_key)
      .deliver_later
  end

  def tour_confirmation_content_key
    if participation.state == "assigned"
      Event::TourParticipationMailer::ASSIGNED
    elsif participation.state == "unconfirmed"
      Event::TourParticipationMailer::UNCONFIRMED
    else
      Event::TourParticipationMailer::APPLIED
    end
  end
end
