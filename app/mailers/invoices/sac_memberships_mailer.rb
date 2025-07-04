# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::SacMembershipsMailer < ApplicationMailer
  include CommonMailerPlaceholders

  MEMBERSHIP_ACTIVATED = "invoices_sac_membership_activated"

  def confirmation(person, section, beitragskategorie)
    @person = person
    @section = section
    @beitragskategorie = beitragskategorie

    headers[:bcc] = [
      section.email,
      SacCas::MV_EMAIL
    ].compact_blank

    I18n.with_locale(person.language) do
      compose(person, MEMBERSHIP_ACTIVATED)
    end
  end
end
