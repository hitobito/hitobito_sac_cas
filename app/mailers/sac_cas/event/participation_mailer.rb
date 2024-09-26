# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationMailer
  include EventMailer
  include MultilingualMailer

  REJECT_APPLIED = "event_participation_reject_applied"
  REJECT_REJECTED = "event_participation_reject_rejected"
  SUMMON = "event_participation_summon"

  def reject_applied(participation)
    compose_email(participation, REJECT_APPLIED)
  end

  def reject_rejected(participation)
    compose_email(participation, REJECT_REJECTED)
  end

  def summon(participation)
    compose_email(participation, SUMMON)
  end

  private

  def compose_email(participation, content_key)
    @participation = participation
    @course = participation.event
    @person = participation.person
    headers[:bcc] = @course.groups.first.course_admin_email
    locales = @course.language.split("_")

    compose_multilingual(@person, content_key, locales)
  end

  private

  def placeholder_book_discount_code
    @course.book_discount_code.to_s
  end
end
