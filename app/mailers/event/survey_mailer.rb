# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::SurveyMailer < ApplicationMailer
  include EventMailer
  include MultilingualMailer

  SURVEY = "event_survey"

  def survey(course, participation)
    @course = course
    @participation = participation
    @person = participation.person
    headers[:bcc] = course.groups.first.course_admin_email
    locales = course.language.split("_")

    compose_multilingual(@person, SURVEY, locales)
  end

  private

  def placeholder_survey_link
    @course.link_survey
  end
end