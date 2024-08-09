# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationMailer
  extend ActiveSupport::Concern

  CONTENT_REJECTED_PARTICIPATION = "event_participation_rejected"
  CONTENT_SUMMON = "event_participation_summon"

  def reject(participation)
    @participation = participation
    person = @participation.person

    compose(person, CONTENT_REJECTED_PARTICIPATION)
  end

  def summon(participation)
    @participation = participation
    person = @participation.person
    headers = {bcc: course.groups.first.course_admin_email}
    locales = course.language.split("_")

    compose(person, CONTENT_SUMMON, nil, headers, locales)
  end

  def compose(recipients, content_key, values = nil, headers = {}, locales = [])
    return if recipients.blank?

    values = if values
      values.merge(
        "event-details" => event_details,
        "application-url" => link_to(participation_url)
      )
    else
      values_for_placeholders(content_key)
    end

    custom_content_mail(recipients, content_key, values, headers, locales)
  end

  private

  def placeholder_event_name
    @participation.event.to_s
  end

  def placeholder_event_number
    @participation.event.number
  end

  def placeholder_person_url
    link_to(group_person_url(course.group_ids.first, @participation.person))
  end

  def course
    @participation.event
  end

  def placeholder_event_link
    link_to group_event_url(group_id: course.group_ids.first, id: course.id)
  end

  def placeholder_book_discount_code
    course.book_discount_code.to_s
  end
end
