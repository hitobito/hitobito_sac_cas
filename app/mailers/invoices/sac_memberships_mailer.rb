# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::SacMembershipsMailer < ApplicationMailer
  include MultilingualMailer
  include CommonMailerPlaceholders

  MEMBERSHIP_ACTIVATED = "invoices_sac_membership_activated"

  def confirmation(person, section, beitragskategorie)
    @person = person
    @section = section
    @beitragskategorie = beitragskategorie
    locales = [person.language]

    headers[:cc] = [section.email].compact_blank
    headers[:bcc] = [SacCas::MV_EMAIL]
    compose_multilingual(person, MEMBERSHIP_ACTIVATED, locales)
  end
end
