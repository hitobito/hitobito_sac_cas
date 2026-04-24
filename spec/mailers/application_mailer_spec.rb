# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  context "layout" do
    it "renders global header and footer" do
      mail = Person::UserImpersonationMailer.completed(people(:mitglied), "Tanja Taker")

      expect(mail.body.to_s).to include(
        "<style>",
        "<header>",
        '<div class="trix-content">',
        "Tanja Taker",
        "<footer>",
        "<address>",
        "Schweizer Alpen-Club SAC\r\n<br />",
        "Monbijoustrasse 61\r\n<br />",
        "3000 Bern 14\r\n<br />",
        "<a href=\"https://www.sac-cas.ch\">https://www.sac-cas.ch</a>"
      )
      expect(mail.body.to_s)
        .to match(/<img .*src="http:\/\/test.host\/packs\/media\/images\/sac_logo_de-.+.svg"/)
    end

    it "renders sektions specific header and footer" do
      group = groups(:bluemlisalp)
      group.update!(
        street: "Blüemlisalpstrasse",
        housenumber: "1",
        zip_code: "3600",
        town: "Thun"
      )
      image = HitobitoSacCas::Wagon.root.join("app", "assets", "images", "pdf", "scissors.png")
      group.logo.attach(io: File.open(image), filename: "scissors.png")

      CustomContent.init_section_specific_contents(group)

      participation = Fabricate(:event_participation,
        event: events(:section_tour),
        participant: people(:mitglied))

      mail = Event::TourParticipationMailer.summon(participation)

      expect(mail.from).to eq(["noreply@localhost"])
      expect(mail.body.to_s).to include(
        "<style>",
        "<header>",
        "Hallo Edmund Hillary",
        "<footer>",
        "<address>",
        "SAC Blüemlisalp\r\n<br>",
        "Blüemlisalpstrasse 1\r\n<br>",
        "3600 Thun"
      )
      expect(mail.body.to_s)
        .to match(/<img .*src="http:\/\/test.host\/rails\/active_storage\/blobs\/redirect\/.+\/scissors.png"/)
    end
  end
end
