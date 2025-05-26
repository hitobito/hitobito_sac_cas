# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacCas::Events::AnnualCourseDuplicateBuilder
  def initialize(source_course, target_year)
    @source_course = source_course
    @target_year = target_year
  end

  def build
    course = @source_course.dup

    course.state = :created
    course.number = determine_next_number(@source_course)

    @source_course.dates.each do |blueprint_date|
      date = course.dates.build(blueprint_date.attributes.except("id"))

      date.start_at = determine_next_date(blueprint_date.start_at.to_date)
      date.finish_at = determine_next_date(blueprint_date.finish_at&.to_date)
    end

    course.application_opening_at = determine_next_date(@source_course.application_opening_at.to_date)
    course.application_closing_at = determine_next_date(@source_course.application_closing_at&.to_date)

    Event::Translation.where(event_id: @source_course.id).find_each do |source_translation|
      course.translations.build(source_translation.attributes.except("id", "event_id"))
    end

    course.groups = @source_course.groups

    course
  end

  private

  def determine_next_date(original_date)
    return unless original_date

    original_week_number = original_date.cweek
    original_weekday_number = original_date.cwday

    Date.commercial(@target_year, original_week_number, original_weekday_number)
  end

  def determine_next_number(course)
    course.number.sub(/^\d{4}-/, "#{@target_year}-")
  end
end
