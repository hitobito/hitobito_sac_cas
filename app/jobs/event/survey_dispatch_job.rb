# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::SurveyDispatchJob < BaseJob
  self.parameters = [:course_id]

  def initialize(course_id)
    super()
    @course_id = course_id
  end

  def perform
    course = Event::Course.find_by(id: @course_id)
    Events::Courses::SurveyDispatcher.new(course).dispatch if course
  end
end
