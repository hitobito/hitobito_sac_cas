# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::NeuanmeldungenMailer do
  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp) }

  context "#approve" do
    let(:mail) { described_class.approve(person, group.layer_group) }

    it "sends email to person" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("SAC Eintritt Antragsbestätigung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Die SAC Blüemlisalp hat deinen Antrag geprüft",
        "wir freuen uns, dir mitzuteilen, dass dein Antrag angenommen wurde."
      )
    end
  end

  context "#reject" do
    let(:mail) { described_class.reject(person, group.layer_group) }

    it "sends email to person" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("SAC Eintritt Antragsablehnung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Die SAC Blüemlisalp hat deinen Antrag geprüft",
        "Leider müssen wir dir mitteilen, dass"
      )
    end

    it "sends email in person's language" do
      person.update!(language: :fr)
      expect(mail.subject).to eq("Demande d'admission au SAC rejetée")
      expect(mail.body.to_s).to include(
        "Bonjour Edmund,",
        "Malheureusement, nous devons vous en informer"
      )
    end
  end
end
