# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::ApplicationClosedMailer < ApplicationMailer
  include EventMailer
  include MultilingualMailer

  NOTICE = "event_application_closed_notice"

  def notice(course)
    @course = course
    @person = course.contact
    locales = course.language.split("_")

    compose_multilingual(course.groups.first.course_admin_email, NOTICE, locales)
  end
end
