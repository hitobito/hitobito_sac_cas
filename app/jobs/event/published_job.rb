# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::PublishedJob < BaseJob
  self.parameters = [:course_id]

  def initialize(course)
    super()
    @course_id = course.id
  end

  def perform
    return unless course # may have been deleted again

    Event::PublishedMailer.notice(course).deliver_now
  end

  def course
    @course ||= Event::Course.find_by(id: @course_id)
  end
end
