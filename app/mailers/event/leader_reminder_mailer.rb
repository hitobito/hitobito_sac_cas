# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::LeaderReminderMailer < ApplicationMailer
  include EventMailer

  REMINDER_NEXT_WEEK = "event_leader_reminder_next_week"
  REMINDER_8_WEEKS = "event_leader_reminder_8_weeks"

  def reminder(course, content_key, leader)
    @course = course
    @leader = leader
    headers = {bcc: course.groups.first.course_admin_email}
    locales = course.language.split("_")

    compose(leader, content_key, headers, locales)
  end

  def placeholder_recipient_name
    @leader.greeting_name
  end
end
