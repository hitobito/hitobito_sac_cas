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

  def create!
    build.tap do |duplicate|
      Event.transaction do
        duplicate.save!

        duplicate.questions.each do |question|
          question.translations.each do |translation|
            translation.event_question_id = question.id
            translation.save!
          end
        end
      end
    end
  end

  def build
    course = @source_course.dup

    course.state = :created
    course.number = determine_next_number(@source_course)
    course.groups = @source_course.groups

    build_dates(course)
    build_translations(course)
    build_questions(course)

    course
  end

  private

  def build_dates(course)
    course.application_opening_at = determine_next_datetime(@source_course.application_opening_at&.to_datetime)
    course.application_closing_at = determine_next_datetime(@source_course.application_closing_at&.to_datetime)

    @source_course.dates.each do |source_date|
      date = course.dates.build(source_date.attributes.except("id"))

      date.start_at = determine_next_datetime(source_date.start_at&.to_datetime)
      date.finish_at = determine_next_datetime(source_date.finish_at&.to_datetime)
    end
  end

  def build_translations(course)
    @source_course.translations.each do |source_translation|
      course.translations.build(source_translation.attributes.except("id", "event_id"))
    end
  end

  def build_questions(course)
    @source_course.questions.each do |source_question|
      question = course.questions.build(source_question.attributes.except("id"))

      source_question.translations.each do |source_translations|
        question.translations.build(source_translations.attributes.except("id", "event_question_id"))
      end
    end
  end

  def determine_next_datetime(original_datetime)
    return unless original_datetime

    original_week_number = original_datetime.cweek
    original_weekday_number = original_datetime.cwday

    DateTime.commercial(@target_year, original_week_number, original_weekday_number,
      original_datetime.hour, original_datetime.minute, original_datetime.second, original_datetime.offset)
  end

  def determine_next_number(course)
    course.number.sub(/^\d{4}-/, "#{@target_year}-")
  end
end
