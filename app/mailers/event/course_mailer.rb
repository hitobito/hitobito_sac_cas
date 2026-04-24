# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::CourseMailer < ApplicationMailer
  include ::CourseMailer
  include MultilingualMailer

  PUBLISHED = "event_published_notice"
  APPLICATION_PAUSED = "event_application_paused_notice"
  APPLICATION_CLOSED = "event_application_closed_notice"

  def published(course, leader)
    @person = leader
    headers[:bcc] = Group.root.course_admin_email
    compose_email(course, leader, PUBLISHED)
  end

  def application_paused(course)
    @person = course.contact
    compose_email(course, Group.root.course_admin_email, APPLICATION_PAUSED)
  end

  def application_closed(course)
    @person = course.contact
    compose_email(course, Group.root.course_admin_email, APPLICATION_CLOSED)
  end

  private

  def compose_email(course, recipient, content_key)
    @course = course
    locales = course.language.split("_")
    compose_multilingual(recipient, content_key, locales)
  end
end
