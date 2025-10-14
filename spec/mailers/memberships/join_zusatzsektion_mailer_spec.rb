# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::JoinZusatzsektionMailer do
  let(:person) { people(:mitglied) }
  let(:body) { mail.body.to_s }
  let(:fees) { Capybara::Node::Simple.new(body).find("table") }

  before { travel_to(Date.new(2024, 7, 1)) }

  context "zusatzsektionsektion requiring approval" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
    let(:mail) { described_class.approval_pending_confirmation(person, group.layer_group, "adult") }

    it "sends confirmation email" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.bcc).to include("bluemlisalp@sac.ch")
      expect(mail.subject).to eq("Zusatzsektion Eintritt Bestellbestätigung")
      expect(body).to include("Sektion: SAC Blüemlisalp", "Hallo Edmund")
      expect(body).to include("Mitgliedernummer: #{person.id}")
      expect(body).to include("Vorname: #{person.first_name}")
      expect(body).to include("Name: #{person.last_name}")
      expect(body).to include("Geburtsdatum: #{I18n.l(person.birthday)}")
      expect(body).to include("E-Mail: #{person.email}")
      expect(body).to include("Strasse und Nr: #{person.street} #{person.housenumber}")
      expect(body).to include("PLZ: #{person.zip_code}")
      expect(body).to include("Über die Aufnahme neuer Mitglieder entscheidet die Sektion")
      expect(body).to include(person_path(person))
      expect(fees).to have_css("tr:nth-of-type(1)", text: "CHF 42.00\r\njährlicher Beitrag")
      expect(fees).to have_css("tr:nth-of-type(2)",
        text: "CHF 21.00\r\n- 50% Rabatt auf den jährlichen Beitrag")
      expect(fees).not_to have_css("tr:nth-of-type(3)")
      expect(fees).to have_css("tfoot tr", text: "CHF 21.00\r\nTotal erstmalig")
    end

    it "includes abroad fees for person living abroad" do
      person.update!(country: "BE")
      expect(fees).to have_css("tr:nth-of-type(3)", text: "CHF 6.50\r\n+ Gebühren Ausland")
    end

    it "uses person language to localize message" do
      # rubocop:todo Layout/LineLength
      CustomContent.get(Memberships::JoinZusatzsektionMailer::APPROVAL_PENDING_CONFIRMATION).update!(
        # rubocop:enable Layout/LineLength
        locale: :fr, label: "fr", subject: "Acceptee", body: "Bonjour"
      )
      person.update!(language: :fr)
      expect(mail.subject).to eq("Acceptee")
    end

    context "beitragskategorie family" do
      let(:person) { people(:familienmitglied) }
      let(:mail) {
        described_class.approval_pending_confirmation(person, group.layer_group, "family")
      }

      it "includes person ids of entire family" do
        expect(mail.to).to eq(["t.norgay@hitobito.example.com"])
        expect(body).to include("Mitgliedernummer: #{person.id} (#{people(:familienmitglied2,
          :familienmitglied_kind).map(&:id).join(", ")})")
      end
    end
  end

  context "sektion not requiring approval" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
    let(:person) { people(:familienmitglied) }
    let(:mail) { described_class.confirmation(person, group.layer_group, "family") }

    it "sends confirmation email" do
      expect(mail.to).to eq(["t.norgay@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.bcc).to include("bluemlisalp@sac.ch")
      expect(mail.subject).to eq("Zusatzsektion Eintritt Bestellbestätigung")
      expect(body).to include("Sektion: SAC Blüemlisalp", "Hallo Tenzing")
      expect(body).to include("Mitgliedernummer: #{person.id}")
      expect(body).to include("Vorname: #{person.first_name}")
      expect(body).to include("Name: #{person.last_name}")
      expect(body).to include("Geburtsdatum: #{I18n.l(person.birthday)}")
      expect(body).to include("E-Mail: #{person.email}")
      expect(body).to include("Strasse und Nr: #{person.street} #{person.housenumber}")
      expect(body).to include("PLZ: #{person.zip_code}")
      expect(body).not_to include("Über die Aufnahme neuer Mitglieder entscheidet die Sektion")
      expect(body).to include(person_path(person))
      expect(fees).to have_css("tr:nth-of-type(1)", text: "CHF 84.00\r\njährlicher Beitrag")
      expect(fees).to have_css("tr:nth-of-type(2)",
        text: "CHF 42.00\r\n- 50% Rabatt auf den jährlichen Beitrag")
      expect(fees).not_to have_css("tr:nth-of-type(3)")
      expect(fees).to have_css("tfoot tr", text: "CHF 42.00\r\nTotal erstmalig")
    end

    it "includes abroad fees for person living abroad" do
      person.update!(country: "BE")
      expect(fees).to have_css("tr:nth-of-type(3)", text: "CHF 6.50\r\n+ Gebühren Ausland")
    end

    it "uses person language to localize message" do
      CustomContent.get(Memberships::JoinZusatzsektionMailer::CONFIRMATION).update!(locale: :fr,
        label: "fr", subject: "Acceptee", body: "Bonjour")
      person.update!(language: :fr)
      expect(mail.subject).to eq("Acceptee")
      expect(mail.body).to include("Bonjour")
    end
  end
end
