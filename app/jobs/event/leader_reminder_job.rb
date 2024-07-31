# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::LeaderReminderJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    Event::Course.joins(:dates)
      .where(event_dates: {start_at: 8.weeks.from_now.all_day})
      .where.not(contact: nil)
      .uniq.each do |course|
      Event::LeaderReminderMailer.reminder(course).deliver_now
    end
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
