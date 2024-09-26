# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module EventMailer
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  private

  def placeholder_recipient_name
    @person.greeting_name
  end

  def placeholder_person_url
    link_to(group_person_url(@course.group_ids.first, @person))
  end

  def placeholder_application_url
    link_to(group_event_participation_url(
      group_id: @course.group_ids.first,
      event_id: @course.id,
      id: @participation.id
    ))
  end

  def placeholder_application_opening_at
    l(@course.application_opening_at)
  end

  def placeholder_application_closing_at
    l(@course.application_closing_at)
  end

  def placeholder_six_weeks_before_start
    l((@course.dates.order(:start_at).first.start_at - 6.weeks).to_date)
  end

  def placeholder_event_name
    @course.name
  end

  def placeholder_event_number
    @course.number
  end

  def placeholder_event_link
    link_to("#{placeholder_event_name} (#{placeholder_event_number})",
      group_event_url(group_id: @course.group_ids.first, id: @course.id))
  end

  # See https://github.com/hitobito/hitobito/blob/master/app/mailers/event/participation_mailer.rb#L112
  def placeholder_event_details
    info = []
    info << labeled(:dates) { join_lines(@course.dates.map(&:to_s)) }
    info << labeled(:motto)
    info << labeled(:cost)
    info << labeled(:description) { convert_newlines_to_breaks(@course.description) }
    info << labeled(:location) { convert_newlines_to_breaks(@course.location) }
    info << labeled(:contact) { escape_html(@course.contact) + br_tag + @course.contact.email }
    join_lines(info.compact, br_tag * 2)
  end

  def labeled(key)
    value = @course.send(key).presence
    if value
      label = @course.class.human_attribute_name(key)
      formatted = block_given? ? yield : value
      escape_html("#{label}:") + br_tag + formatted
    end
  end
end
