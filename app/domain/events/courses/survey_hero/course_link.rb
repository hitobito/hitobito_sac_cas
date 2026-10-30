# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Courses::SurveyHero
  class CourseLink
    DATE_FORMAT = "%d.%m.%Y"
    LOCALES = {"de" => :de, "de_fr" => :de, "fr" => :fr, "it" => :it}.freeze

    attr_reader :course, :client

    def initialize(course, client: Client.new)
      @course = course
      @client = client
    end

    def create
      url = client.copy_collector(
        course.survey_hero_survey_key,
        course.survey_hero_collector_key,
        name: "SAC Kursumfrage: #{course_name} (#{course.number})"
      )
      "#{url}#{url.include?("?") ? "&" : "?"}#{query.to_query}"
    end

    private

    def query
      {
        "course-id" => course.number,
        "coursename" => course_name,
        "event-start" => course.start_at.strftime(DATE_FORMAT),
        "event-finish" => course.finish_at.strftime(DATE_FORMAT)
      }
    end

    def course_name
      @course_name ||= I18n.with_locale(LOCALES.fetch(course.language, :de)) { course.name }
    end
  end
end
