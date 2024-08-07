# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::ApplicationPausedMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  NOTICE = "event_application_paused_notice"

  def notice(course)
    @course = course
    locales = course.language.split("_")

    compose(course.groups.first.course_admin_email, NOTICE, {}, locales)
  end

  private

  def placeholder_event_name
    @course.name
  end

  def placeholder_event_number
    @course.number
  end

  def placeholder_event_link
    link_to "#{placeholder_event_name} (#{placeholder_event_number})",
      group_event_url(group_id: @course.group_ids.first, id: @course.id)
  end

  def placeholder_event_details
    info = []
    info << labeled(:dates) { @course.dates.map(&:to_s).join("<br>") }
    info << labeled(:motto)
    info << labeled(:cost)
    info << labeled(:description) { @course.description.gsub("\n", "<br>") }
    info << labeled(:location) { @course.location.gsub("\n", "<br>") }
    info << labeled(:contact) { "#{@course.contact}<br>#{@course.contact.email}" }
    info.compact.join("<br><br>")
  end

  def labeled(key)
    value = @course.send(key).presence
    if value
      label = @course.class.human_attribute_name(key)
      formatted = block_given? ? yield : value
      "#{label}:<br>#{formatted}"
    end
  end
end
