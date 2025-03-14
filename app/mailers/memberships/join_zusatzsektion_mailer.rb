# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Memberships::JoinZusatzsektionMailer < ApplicationMailer
  include MultilingualMailer
  include CommonMailerPlaceholders

  CONFIRMATION = "join_zusatzsektion_confirmation"
  APPROVAL_PENDING_CONFIRMATION = "join_zusatzsektion_approval_pending_confirmation"

  def confirmation(person, section, beitragskategorie)
    send_mail(person, section, beitragskategorie, CONFIRMATION)
  end

  def approval_pending_confirmation(person, section, beitragskategorie)
    send_mail(person, section, beitragskategorie, APPROVAL_PENDING_CONFIRMATION)
  end

  private

  def send_mail(person, section, beitragskategorie, content_key)
    @person = person
    @section = section
    @beitragskategorie = beitragskategorie
    headers[:bcc] = [section.email, SacCas::MV_EMAIL].compact_blank
    locales = [person.language]

    compose_multilingual(person, content_key, locales)
  end
end
