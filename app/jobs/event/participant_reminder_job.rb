# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::ParticipantReminderJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    participations_with_missing_answers.each do |participation|
      Event::ParticipantReminderMailer.reminder(participation).deliver_later
    end
  end

  def participations_with_missing_answers
    Event::Participation.active.joins(:answers, answers: :question, event: :dates)
      .where(event_dates: {start_at: 6.weeks.from_now.all_day})
      .where(event_questions: {admin: true})
      .where(event_answers: {answer: Event::Answer::MISSING})
      .distinct
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
