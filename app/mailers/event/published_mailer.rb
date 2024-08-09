# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::PublishedMailer < ApplicationMailer
  include EventMailer

  EVENT_LEADER_ROLES = [Event::Role::Leader, Event::Role::AssistantLeader].map(&:sti_name)
  NOTICE = "event_published_notice"

  def notice(course)
    @course = course
    headers = {bcc: course.groups.first.course_admin_email}
    locales = course.language.split("_")
    event_leaders = Person.where(id: course.participations.joins(:roles)
      .where(roles: {type: EVENT_LEADER_ROLES}).pluck(:person_id))

    compose(event_leaders, NOTICE, headers, locales)
  end
end
