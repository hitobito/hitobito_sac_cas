# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::SurveyDispatchScheduleJob < RecurringJob
  CATCH_UP_DAYS = 7
  # SurveyHero rejects requests less than 500ms apart, see
  # https://developer.surveyhero.com/api/#rate-limiting
  SURVEY_HERO_REQUEST_INTERVAL = 1.second

  private

  def perform_internal
    courses.pluck(:id).each_with_index do |course_id, index|
      Event::SurveyDispatchJob.new(course_id)
        .enqueue!(run_at: Time.zone.now + (index * SURVEY_HERO_REQUEST_INTERVAL))
    end
  end

  def courses
    Event::Course
      .where(state: Events::Courses::State::EMAIL_DISPATCH_CONDITIONS[:survey])
      .where(survey_auto_send: true, link_survey: [nil, ""])
      .where.not(survey_hero_survey_key: [nil, ""])
      .joins(:dates)
      .group(:id)
      .having("MAX(GREATEST(event_dates.start_at, event_dates.finish_at)) BETWEEN ? AND ?",
        course_end_range.begin, course_end_range.end)
  end

  def course_end_range
    (Time.zone.today - CATCH_UP_DAYS).beginning_of_day..Time.zone.today.end_of_day
  end

  def next_run
    Time.zone.now.tomorrow.change(hour: 8)
  end
end
