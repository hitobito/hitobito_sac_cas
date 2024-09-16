# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Memberships::LeaveZusatzsektionMailer < ApplicationMailer
  CONFIRMATION = "memberships_leave_zusatzsektion_confirmation"

  def confirmation(person, sektion_name, terminate_on)
    @person = person
    @sektion_name = sektion_name
    @terminate_on = terminate_on
    headers[:cc] = Group::Geschaeftsstelle.first.email

    compose(person, CONFIRMATION)
  end

  private

  def placeholder_person_name
    @person.to_s
  end

  def placeholder_sektion_name
    @sektion_name
  end

  def placeholder_terminate_on
    @terminate_on
  end
end
