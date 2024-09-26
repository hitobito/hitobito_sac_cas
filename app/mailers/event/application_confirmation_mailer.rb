# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::ApplicationConfirmationMailer < ApplicationMailer
  include EventMailer
  include MultilingualMailer

  APPLIED = "course_application_confirmation_applied"
  UNCONFIRMED = "course_application_confirmation_unconfirmed"
  ASSIGNED = "course_application_confirmation_assigned"

  def confirmation(participation, content_key)
    @participation = participation
    @person = participation.person
    @course = participation.event
    headers[:bcc] = @course.groups.first.course_admin_email
    locales = @course.language.split("_")

    compose_multilingual(@person, content_key, locales)
  end

  private

  def placeholder_missing_information
    missing = [nil, "", "nein", "non", "no"]
    missing_questions = join_lines(Event::Question.admin.joins(:answers)
      .where(answers: {participation: @participation, answer: missing})
      .pluck(:question)
      .map { |question| [content_tag(:li, question)] }.flatten, nil)

    return "" if missing_questions.blank?

    escape_html(t("event.participations.missing_information")) + br_tag + content_tag(:ul, missing_questions)
  end

  def content_tag(name, content = nil)
    content = yield if block_given?
    "<#{name}>".html_safe + content + "</#{name}>".html_safe
  end
end
