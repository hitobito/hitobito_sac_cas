# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationMailer
  include MultilingualMailer
  include CourseMailer

  REJECT_APPLIED_PARTICIPATION = "event_participation_reject_applied"
  REJECT_REJECTED_PARTICIPATION = "event_participation_reject_rejected"
  SUMMONED_PARTICIPATION = "event_participation_summon"

  def confirmation(participation)
    @course = participation.event

    super
  end

  def reject_applied(participation)
    compose_email(participation, REJECT_APPLIED_PARTICIPATION)
  end

  def reject_rejected(participation)
    compose_email(participation, REJECT_REJECTED_PARTICIPATION)
  end

  def reject_unconfirmed(participation)
    compose_email(participation, REJECT_APPLIED_PARTICIPATION)
  end

  def summon(participation)
    compose_email(participation, SUMMONED_PARTICIPATION)
  end

  private

  def compose_email(participation, content_key)
    @participation = participation
    @course = participation.event
    @person = participation.person
    headers[:bcc] = Group.root.course_admin_email
    locales = @course.language.split("_")

    compose_multilingual(@person, content_key, locales)
  end

  private

  def placeholder_book_discount_code
    @course.book_discount_code.to_s
  end
end
