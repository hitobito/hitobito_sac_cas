# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::SurveyJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    participations_of_courses_finished_3_days_ago.each do |participation|
      Event::SurveyMailer.survey(participation).deliver_later
    end
  end

  def participations_of_courses_finished_3_days_ago
    Event::Participation.joins(:event, event: :dates)
      .where(state: :attended)
      .where(event_dates: {finish_at: 3.days.ago.all_day})
      .where.not(event: {link_survey: nil})
      .distinct
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
