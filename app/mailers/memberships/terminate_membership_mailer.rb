# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Memberships::TerminateMembershipMailer < ApplicationMailer
  TERMINATE_MEMBERSHIP = "memberships_terminate_sac_membership_confirmation"
  LEAVE_ZUSATZSEKTION = "memberships_leave_zusatzsektion_confirmation"

  def terminate_membership(person, sektion, terminate_on)
    send_confirmation(TERMINATE_MEMBERSHIP, person, sektion, terminate_on)
  end

  def leave_zusatzsektion(person, sektion, terminate_on)
    send_confirmation(LEAVE_ZUSATZSEKTION, person, sektion, terminate_on)
  end

  private

  def send_confirmation(key, person, sektion, terminate_on)
    @person = person
    @sektion = sektion
    @terminate_on = terminate_on
    headers[:cc] = Group::Geschaeftsstelle.first.email
    headers[:bcc] = [sektion.email, SacCas::MV_EMAIL].compact_blank

    compose(person, key)
  end

  def placeholder_person_name
    @person.to_s
  end

  def placeholder_sektion_name
    @sektion.name
  end

  def placeholder_terminate_on
    @terminate_on
  end
end
