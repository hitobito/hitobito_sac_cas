# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class SwitchStammsektionMailer < ApplicationMailer
    CONFIRMATION = "memberships_switch_stammsektion_confirmation"

    def confirmation(person, sektion, switch_on_text)
      values = [
        %W[person-name #{person}],
        %W[group-name #{sektion}],
        %W[switch-date #{switch_on_text}]
      ].to_h
      custom_headers = {cc: Group::Geschaeftsstelle.first.email}
      custom_content_mail([person], CONFIRMATION, values, custom_headers)
    end
  end
end
