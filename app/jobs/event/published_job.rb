# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::PublishedJob < BaseJob
  self.parameters = %i[course_id leader_id]

  def initialize(course, leader)
    super()
    @course_id = course.id
    @leader_id = leader.id
  end

  def perform
    return unless course # may have been deleted again

    Event::PublishedMailer.notice(course, leader).deliver_now
  end

  def course
    @course ||= Event::Course.find_by(id: @course_id)
  end

  def leader
    @leader ||= Person.find_by(id: @leader_id)
  end
end
