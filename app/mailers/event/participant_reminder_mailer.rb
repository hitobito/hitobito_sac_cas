# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::ParticipantReminderMailer < ApplicationMailer
  include EventMailer
  include MultilingualMailer

  REMINDER = "event_participant_reminder"

  def reminder(participation)
    @participation = participation
    @person = participation.person
    @course = participation.event
    headers[:bcc] = @course.groups.first.course_admin_email
    locales = @course.language.split("_")

    compose_multilingual(@person, REMINDER, locales)
  end
end
