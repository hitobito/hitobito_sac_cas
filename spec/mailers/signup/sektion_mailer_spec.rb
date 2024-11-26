# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Signup::SektionMailer do
  let(:person) { people(:mitglied) }
  let(:body) { mail.body.to_s }

  context "sektion requiring approval" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
    let(:mail) { described_class.approval_pending_confirmation(person, group.layer_group, "adult") }

    it "sends confirmation email" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.subject).to eq("SAC Eintritt Bestellbestätigung")
      expect(body).to include("Sektion: SAC Blüemlisalp", "Hallo Edmund")
      expect(body).to include("Über die Aufnahme neuer Mitglieder entscheidet die Sektion")
      expect(body).to include(group_person_path(person.primary_group, person))
      expect(body).to include("<td>CHF 127.00")
    end

    it "includes abroad fees for person living abroad" do
      person.update!(country: "BE")
      expect(body).to include("+ Gebühren Ausland")
      expect(body).to include("<td>CHF 10.00")
    end

    it "uses person language to localize message" do
      CustomContent.get(Signup::SektionMailer::APPROVAL_PENDING_CONFIRMATION).update!(locale: :fr, label: "fr", subject: "Acceptee", body: "Bonjour")
      person.update!(language: :fr)
      expect(mail.subject).to eq("Acceptee")
    end
  end

  context "sektion not requiring approval" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
    let(:mail) { described_class.confirmation(person, group.layer_group, "family") }

    it "sends confirmation email" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.subject).to eq("SAC Eintritt Bestellbestätigung")
      expect(body).to include "Teil des grössten Bergsportverbands der Schweiz bist"
      expect(body).to include(group_person_path(person.primary_group, person))
      expect(body).to include(
        "Sektion: SAC Blüemlisalp",
        "Mitgliedschaftskategorie: Familie",
        "Geburtsdatum: 01.01.2000",
        "Strasse und Nr: Ophovenerstrasse 79a",
        "Viel Spass beim SAC!"
      )
      expect(body).to include("<td>CHF 179.00")
    end

    it "includes abroad fees for person living abroad" do
      person.update!(country: "BE")
      expect(body).to include("+ Gebühren Ausland")
      expect(body).to include("<td>CHF 10.00")
    end

    it "uses person language to localize message" do
      CustomContent.get(Signup::SektionMailer::CONFIRMATION).update!(locale: :fr, label: "fr", subject: "Acceptee", body: "Bonjour")
      person.update!(language: :fr)
      expect(mail.subject).to eq("Acceptee")
      expect(mail.body).to include("Bonjour")
    end
  end
end
