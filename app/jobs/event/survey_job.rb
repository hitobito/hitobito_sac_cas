# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::SurveyJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    courses_finished_3_days_ago.each do |course|
      course.participations.where(state: :attended).find_each do |participation|
        Event::SurveyMailer.survey(course, participation).deliver_later
      end
    end
  end

  def courses_finished_3_days_ago
    Event::Course.joins(:dates, :participations)
      .where(event_dates: {finish_at: 3.days.ago.all_day})
      .where.not(link_survey: nil)
      .distinct
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
