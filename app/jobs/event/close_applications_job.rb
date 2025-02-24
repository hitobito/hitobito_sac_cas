# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::CloseApplicationsJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    Event::Course
      .where(state: Events::Courses::State::APPLICATION_OPEN_STATES)
      .where(application_closing_at: ...Time.zone.today)
      .find_each do |course|
        course.update_column(:state, :application_closed)
        recipient = Group.root.course_admin_email
        Event::ApplicationClosedMailer.notice(course).deliver_later if recipient.present?
      end
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
