# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Events::Courses::SurveyDispatcher
  attr_reader :course, :client

  def initialize(course, client: Events::Courses::SurveyHero::Client.new)
    @course = course
    @client = client
  end

  def dispatch
    return unless dispatchable?

    course.update!(link_survey: Events::Courses::SurveyHero::CourseLink.new(course, client:).create)
    course.participants_scope.each do |participation|
      Event::CourseParticipationMailer.survey(participation).deliver_later
    end
  rescue Events::Courses::SurveyHero::Client::Error => e
    log_link_creation_failed(e)
  end

  private

  def log_link_creation_failed(error)
    Hitobito.logger.error_replace(
      "kursumfragen",
      I18n.t("events.courses.survey_dispatcher.link_creation_failed"),
      subject: course,
      payload: error.message
    )
  end

  def dispatchable?
    course.survey_auto_send? &&
      course.survey_hero_survey_key.present? &&
      course.survey_hero_collector_key.present? &&
      course.link_survey.blank? &&
      course.survey_email_possible?
  end
end
