# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::Participations::SendMailsController
  extend ActiveSupport::Concern

  private

  # Course participation mails

  def dispatch_event_participation_canceled_mail
    Event::CourseParticipationMailer.canceled(participation).deliver_later
  end

  def dispatch_event_canceled_no_leader_mail
    Event::CourseParticipationMailer.event_canceled_no_leader(participation).deliver_later
  end

  def dispatch_event_canceled_minimum_participants_mail
    Event::CourseParticipationMailer.event_canceled_minimum_participants(
      participation
    ).deliver_later
  end

  def dispatch_event_canceled_weather_mail
    Event::CourseParticipationMailer.event_canceled_weather(participation).deliver_later
  end

  def dispatch_event_participation_summon_mail
    Event::CourseParticipationMailer.summon(participation).deliver_later
  end

  def dispatch_course_application_confirmation_assigned_mail
    Event::CourseParticipationMailer.confirmation(participation, mail_type).deliver_later
  end

  def dispatch_course_application_confirmation_unconfirmed_mail
    Event::CourseParticipationMailer.confirmation(participation, mail_type).deliver_later
  end

  def dispatch_course_application_confirmation_applied_mail
    Event::CourseParticipationMailer.confirmation(participation, mail_type).deliver_later
  end

  def dispatch_event_participation_reject_rejected_mail
    Event::CourseParticipationMailer.reject_rejected(participation).deliver_later
  end

  def dispatch_event_participation_reject_applied_mail
    Event::CourseParticipationMailer.reject_applied(participation).deliver_later
  end

  def dispatch_event_survey_mail
    Event::CourseParticipationMailer.survey(participation).deliver_later
  end

  def dispatch_event_participant_reminder_mail
    Event::CourseParticipationMailer.reminder(participation).deliver_later
  end

  def dispatch_event_leader_reminder_next_week_mail
    Event::CourseParticipationMailer.leader_reminder(participation, mail_type).deliver_later
  end

  def dispatch_event_leader_reminder_8_weeks_mail
    Event::CourseParticipationMailer.leader_reminder(participation, mail_type).deliver_later
  end

  def dispatch_event_published_notice_mail
    Event::CourseMailer.published(participation.event, participation.person).deliver_later
  end

  # Tour participation mails

  def dispatch_event_tour_application_confirmation_unconfirmed_mail
    Event::TourParticipationMailer.confirmation(participation, mail_type).deliver_later
  end

  def dispatch_event_tour_application_confirmation_assigned_mail
    Event::TourParticipationMailer.confirmation(participation, mail_type).deliver_later
  end

  def dispatch_event_tour_participation_reject_mail
    Event::TourParticipationMailer.reject(participation).deliver_later
  end

  def dispatch_event_tour_participation_summon_mail
    Event::TourParticipationMailer.summon(participation).deliver_later
  end

  def dispatch_event_tour_closing_mail
    Event::TourParticipationMailer.closing(participation).deliver_later
  end

  def dispatch_event_tour_canceled_no_leader_mail
    Event::TourParticipationMailer.canceled_no_leader(participation).deliver_later
  end

  def dispatch_event_tour_canceled_minimum_participants_mail
    Event::TourParticipationMailer.canceled_minimum_participants(participation).deliver_later
  end

  def dispatch_event_tour_canceled_weather_mail
    Event::TourParticipationMailer.canceled_weather(participation).deliver_later
  end

  def dispatch_event_tour_participation_canceled_mail
    Event::TourParticipationMailer.canceled(participation).deliver_later
  end
end
