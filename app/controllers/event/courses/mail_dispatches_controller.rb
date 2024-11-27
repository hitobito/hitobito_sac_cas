# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Courses::MailDispatchesController < ApplicationController
  def create
    authorize!(:create, course)
  
    case mail_type
    when "survey"
      send_survey_mails
    when "leader_reminder"
      send_leader_reminder_mails
    end
  end

  private

  def send_survey_mails
    if course.link_survey.present?
      send_mails(attended_participations, Event::SurveyMailer, :survey)
      redirect_to_success(attended_participations.count)
    else
      redirect_to_warning
    end
  end

  def send_leader_reminder_mails
    send_mails(leader_participations, Event::LeaderReminderMailer, :reminder, Event::LeaderReminderMailer::REMINDER_NEXT_WEEK)
    redirect_to_success(leader_participations.count)
  end

  def send_mails(recipients, mailer_class, method_name, *args)
    recipients.each do |recipient|
      mailer_class.public_send(method_name, recipient, *args).deliver_later
    end
  end

  def redirect_to_success(count)
    redirect_to group_event_path(group, course), flash: {notice: t(".success", n: count)}
  end
  
  def redirect_to_warning
    redirect_to group_event_path(group, course), flash: {alert: t(".warning")}
  end

  def leader_participations
    @leader_participations ||= course.participations
                                     .joins(:roles)
                                     .where(roles: {type: Event::Course::Role::Leader.sti_name})
                                     .distinct_on(:id)
  end

  def attended_participations = @attended_participations ||= course.participants_scope

  def group = @group ||= Group.find(params[:group_id])
  
  def course = @course ||= Event::Course.find(params[:event_id])

  def mail_type = @mail_type ||= params[:mail_type]
end
