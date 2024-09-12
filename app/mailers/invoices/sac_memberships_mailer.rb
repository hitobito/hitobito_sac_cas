# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::SacMembershipsMailer < ApplicationMailer
  MEMBERSHIP_ACTIVATED = "invoices_sac_membership_activated"

  def confirmation(person)
    @person = person
    headers = {}
    locales = [person.language]

    compose(person, MEMBERSHIP_ACTIVATED, headers, locales)
  end

  private

  def placeholder_first_name
    @person.first_name
  end

  def placeholder_profile_url
    group_person_url(@person.default_group_id, @person.id)
  end
end
