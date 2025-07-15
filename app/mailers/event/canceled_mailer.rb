# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::CanceledMailer < ApplicationMailer
  include CourseMailer
  include MultilingualMailer

  MINIMUM_PARTICIPANTS = "event_canceled_minimum_participants"
  NO_LEADER = "event_canceled_no_leader"
  WEATHER = "event_canceled_weather"

  def minimum_participants(participation, leader_emails)
    send_mail(MINIMUM_PARTICIPANTS, participation, leader_emails)
  end

  def no_leader(participation, leader_emails)
    send_mail(NO_LEADER, participation, leader_emails)
  end

  def weather(participation, leader_emails)
    send_mail(WEATHER, participation, leader_emails)
  end

  private

  def send_mail(content_key, participation, leader_emails)
    @participation = participation
    @course = participation.event
    @person = participation.person
    headers[:cc] = leader_emails
    headers[:bcc] = Group.root.course_admin_email
    locales = @course.language.split("_")

    compose_multilingual(@person, content_key, locales)
  end
end
