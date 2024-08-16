# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::ApplicationConfirmationMailer < ApplicationMailer
  include EventMailer

  APPLIED = "course_application_confirmation_applied"
  UNCONFIRMED = "course_application_confirmation_unconfirmed"
  ASSIGNED = "course_application_confirmation_assigned"

  def confirmation(participation, content_key)
    @participation = participation
    @course = participation.event
    headers = {bcc: @course.groups.first.course_admin_email}
    locales = @course.language.split("_")

    compose(@participation.person, content_key, headers, locales)
  end

  private

  def placeholder_recipient_name
    @participation.person.greeting_name
  end

  def placeholder_person_url
    link_to(person_url(@participation.person))
  end

  def placeholder_application_url
    link_to(group_event_participation_url(
      group_id: @course.groups.first.id,
      event_id: @course.id,
      id: @participation.id
    ))
  end

  def placeholder_missing_information
    missing_questions = Event::Question.admin.joins(:answers)
      .where(answers: {participation: @participation, answer: [nil, "", "nein", "non", "no"]})
      .pluck(:question).map { |question| ["<li>", question].join }.join

    return "" if missing_questions.blank?

    "#{t("event.participations.missing_information")}<br><ul>#{missing_questions}</ul>"
  end
end
