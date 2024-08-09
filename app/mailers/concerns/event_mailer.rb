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
    @course.contact.greeting_name
  end

  def placeholder_application_opening_at
    l(@course.application_opening_at)
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
