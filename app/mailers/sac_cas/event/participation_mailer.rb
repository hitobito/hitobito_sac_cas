# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationMailer
  extend ActiveSupport::Concern
  include EventMailer

  CONTENT_REJECTED_PARTICIPATION = "event_participation_rejected"
  CONTENT_SUMMON = "event_participation_summon"

  def reject(participation)
    compose_email(participation, CONTENT_REJECTED_PARTICIPATION)
  end

  def summon(participation)
    compose_email(participation, CONTENT_SUMMON)
  end

  private

  def compose_email(participation, content_key)
    @participation = participation
    @course = @participation.event
    person = @participation.person
    headers = {bcc: @course.groups.first.course_admin_email}
    locales = @course.language.split("_")

    compose(person, content_key, nil, headers, locales)
  end

  def compose(recipients, content_key, values = nil, headers = {}, locales = [])
    return if recipients.blank?

    # Assert the current mailer's view context is stored as Draper::ViewContext.
    # This is done in the #view_context method overriden by Draper.
    # Otherwise, decorators will not have access to all helper methods.
    view_context

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

  def placeholder_person_url
    link_to(group_person_url(@course.group_ids.first, @participation.person))
  end

  def placeholder_book_discount_code
    @course.book_discount_code.to_s
  end

  def placeholder_recipient_name
    person.greeting_name
  end
end
