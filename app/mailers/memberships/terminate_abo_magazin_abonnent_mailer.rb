# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Memberships::TerminateAboMagazinAbonnentMailer < ApplicationMailer
  include CommonMailerPlaceholders

  TERMINATE_ABONNENT = "memberships_terminate_abo_magazin_abonnent"

  def terminate_abonnent(person, terminate_on)
    @person = person
    @terminate_on = terminate_on
    recipient = person

    I18n.with_locale(person.language) do
      @terminate_on = I18n.l(terminate_on)
      compose(recipient, TERMINATE_ABONNENT)
    end
  end

  private

  def placeholder_person_name
    @person.to_s
  end

  def placeholder_terminate_on
    @terminate_on
  end
end
