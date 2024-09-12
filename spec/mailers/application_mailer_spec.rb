# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  context "layout" do
    it "renders logo and footer" do
      mail = Person::UserImpersonationMailer.completed(people(:mitglied), "Tanja Taker")

      expect(mail.body).to include("<style>")
      expect(mail.body).to include('<div class="trix-content">')
      expect(mail.body).to include("Tanja Taker")
      expect(mail.body).to include('src="http://test.host/packs/media/images/sac_logo_de')
      expect(mail.body).to include("<footer>")
      expect(mail.body).to include("<address>")
      expect(mail.body).to include("Monbijoustrasse 61")
    end
  end
end
