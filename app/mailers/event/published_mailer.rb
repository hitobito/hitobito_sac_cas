# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::PublishedMailer < ApplicationMailer
  include CourseMailer
  include MultilingualMailer

  NOTICE = "event_published_notice"

  def notice(course, leader)
    @course = course
    @person = leader
    headers[:bcc] = course.groups.first.course_admin_email
    locales = course.language.split("_")

    compose_multilingual(leader, NOTICE, locales)
  end
end
