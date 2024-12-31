# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  context "layout" do
    it "renders footer" do
      mail = Person::UserImpersonationMailer.completed(people(:mitglied), "Tanja Taker")

      expect(mail.body.to_s).to include(
        "<style>",
        '<div class="trix-content">',
        "Tanja Taker",
        "<footer>",
        "<address>",
        "Monbijoustrasse 61"
      )
    end
  end
end
