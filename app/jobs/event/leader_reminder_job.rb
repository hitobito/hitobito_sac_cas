# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::LeaderReminderJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    send_reminder(1.week.from_now, Event::LeaderReminderMailer::REMINDER_NEXT_WEEK)
    send_reminder(8.weeks.from_now, Event::LeaderReminderMailer::REMINDER_8_WEEKS)
  end

  def send_reminder(start_at, content_key)
    leader_participations_of_events_starting_at(start_at).each do |participation|
      Event::LeaderReminderMailer.reminder(participation, content_key).deliver_now
    end
  end

  def leader_participations_of_events_starting_at(start_at)
    Event::Participation.joins(:roles, :event, event: :dates)
      .where(roles: {type: Event::Course::LEADER_ROLES})
      .where(event_dates: {start_at: start_at.all_day})
      .distinct
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
