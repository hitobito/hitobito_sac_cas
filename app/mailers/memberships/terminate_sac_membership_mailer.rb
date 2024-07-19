# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class TerminateSacMembershipMailer < ApplicationMailer
    CONFIRMATION = "memberships_terminate_sac_membership_confirmation"

    def confirmation(person, sektion_name, terminate_on)
      values = [
        %W[person-name #{person}],
        %W[sektion-name #{sektion_name}],
        %W[terminate-on #{terminate_on}]
      ].to_h
      custom_headers = {cc: Group::Geschaeftsstelle.first.email}
      custom_content_mail([person], CONFIRMATION, values, custom_headers)
    end
  end
end
