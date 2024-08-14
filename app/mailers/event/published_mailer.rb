# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::PublishedMailer < ApplicationMailer
  include EventMailer

  EVENT_LEADER_ROLES = [Event::Role::Leader, Event::Role::AssistantLeader].map(&:sti_name)
  NOTICE = "event_published_notice"

  def notice(course, leader)
    @course = course
    @leader = leader
    headers = {bcc: course.groups.first.course_admin_email}
    locales = course.language.split("_")

    compose(leader, NOTICE, headers, locales)
  end

  private

  def placeholder_recipient_name
    @leader.greeting_name
  end
end
