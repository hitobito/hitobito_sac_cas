# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::Participations::MailDispatchesController
  extend ActiveSupport::Concern

  prepended do
    def mail_type_valid?
      if (participation.roles.map(&:type) & Event::Course::LEADER_ROLES).any?
        Event::Participation::MANUALLY_SENDABLE_LEADERSHIP_MAILS.include?(mail_type)
      else
        Event::Participation::MANUALLY_SENDABLE_PARTICIPANT_MAILS.include?(mail_type)
      end
    end
  end

  private

  def send_event_participation_canceled_mail = Event::ParticipationCanceledMailer.confirmation(participation).deliver_later

  def send_event_canceled_no_leader_mail = Event::CanceledMailer.no_leader(participation).deliver_later

  def send_event_canceled_minimum_participants_mail = Event::CanceledMailer.minimum_participants(participation).deliver_later

  def send_event_canceled_weather_mail = Event::CanceledMailer.weather(participation).deliver_later

  def send_event_participation_summon_mail = Event::ParticipationMailer.summon(participation).deliver_later

  def send_course_application_confirmation_assigned_mail = Event::ApplicationConfirmationMailer.confirmation(participation, mail_type).deliver_later

  def send_event_participation_reject_rejected_mail = Event::ParticipationMailer.reject_rejected(participation).deliver_later

  def send_event_participation_reject_applied_mail = Event::ParticipationMailer.reject_applied(participation).deliver_later

  def send_event_survey_mail = Event::SurveyMailer.survey(participation).deliver_later

  def send_course_application_confirmation_unconfirmed_mail = Event::ApplicationConfirmationMailer.confirmation(participation, mail_type).deliver_later

  def send_course_application_confirmation_applied_mail = Event::ApplicationConfirmationMailer.confirmation(participation, mail_type).deliver_later

  def send_event_published_notice_mail = Event::PublishedMailer.notice(event, participation.person).deliver_later

  def send_event_leader_reminder_next_week_mail = Event::LeaderReminderMailer.reminder(participation, mail_type).deliver_later

  def send_event_leader_reminder_8_weeks_mail = Event::LeaderReminderMailer.reminder(participation, mail_type).deliver_later
end
