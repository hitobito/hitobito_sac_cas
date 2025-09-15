# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::ParticipationCanceledMailer < ApplicationMailer
  include CourseMailer
  include CommonMailerPlaceholders
  include MultilingualMailer

  CONFIRMATION = "event_participation_canceled"

  def confirmation(participation)
    @participation = participation
    @course = participation.event
    @person = participation.person
    headers[:bcc] = Group.root.course_admin_email
    locales = @course.language.split("_")

    compose_multilingual(@person, CONFIRMATION, locales)
  end
end
