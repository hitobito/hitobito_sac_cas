# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::CourseParticipationMailer < ApplicationMailer
  include MultilingualMailer
  include CourseMailer
  include CommonMailerPlaceholders

  APPLIED = "course_application_confirmation_applied"
  UNCONFIRMED = "course_application_confirmation_unconfirmed"
  ASSIGNED = "course_application_confirmation_assigned"
  REJECT_APPLIED_PARTICIPATION = "event_participation_reject_applied"
  REJECT_REJECTED_PARTICIPATION = "event_participation_reject_rejected"
  SUMMONED_PARTICIPATION = "event_participation_summon"
  REMINDER = "event_participant_reminder"
  LEADER_REMINDER_NEXT_WEEK = "event_leader_reminder_next_week"
  LEADER_REMINDER_8_WEEKS = "event_leader_reminder_8_weeks"
  CANCELED_PARTICIPATION = "event_participation_canceled"
  SURVEY = "event_survey"
  EVENT_CANCELED_MINIMUM_PARTICIPANTS = "event_canceled_minimum_participants"
  EVENT_CANCELED_NO_LEADER = "event_canceled_no_leader"
  EVENT_CANCELED_WEATHER = "event_canceled_weather"

  def confirmation(participation, content_key)
    compose_email(participation, content_key)
  end

  def reject_applied(participation)
    compose_email(participation, REJECT_APPLIED_PARTICIPATION)
  end

  def reject_rejected(participation)
    compose_email(participation, REJECT_REJECTED_PARTICIPATION)
  end

  def reject_unconfirmed(participation)
    compose_email(participation, REJECT_APPLIED_PARTICIPATION)
  end

  def summon(participation)
    compose_email(participation, SUMMONED_PARTICIPATION)
  end

  def reminder(participation)
    compose_email(participation, REMINDER)
  end

  def leader_reminder(participation, content_key)
    compose_email(participation, content_key)
  end

  def canceled(participation)
    compose_email(participation, CANCELED_PARTICIPATION)
  end

  def survey(participation)
    compose_email(participation, SURVEY)
  end

  def event_canceled_minimum_participants(participation)
    compose_email(participation, EVENT_CANCELED_MINIMUM_PARTICIPANTS)
  end

  def event_canceled_no_leader(participation)
    compose_email(participation, EVENT_CANCELED_NO_LEADER)
  end

  def event_canceled_weather(participation)
    compose_email(participation, EVENT_CANCELED_WEATHER)
  end

  private

  def compose_email(participation, content_key)
    @participation = participation
    @course = participation.event
    @person = participation.person
    headers[:bcc] = Group.root.course_admin_email
    locales = @course.language.split("_")

    compose_multilingual(@person, content_key, locales)
  end

  private

  def placeholder_book_discount_code
    @course.book_discount_code.to_s
  end

  def placeholder_survey_link
    link_to(@course.link_survey)
  end
end
