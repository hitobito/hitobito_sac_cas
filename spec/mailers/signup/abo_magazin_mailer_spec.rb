# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Signup::AboMagazinMailer do
  let(:person) { people(:mitglied) }
  let(:body) { mail.body.to_s }

  let(:group) { groups(:abo_die_alpen) }
  let(:mail) { described_class.confirmation(person, group, false) }
  let(:custom_content) { CustomContent.get(Signup::AboMagazinMailer::CONFIRMATION) }

  before do
    person.update(address_care_of: "1A", postbox: "123")
    Group.root.update!(abo_alpen_fee: 60, abo_alpen_postage_abroad: 16)
  end

  it "sends confirmation email" do
    expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
    expect(mail.bcc).to be_nil
    expect(mail.subject).to eq("Bestellbestätigung - Die Alpen DE")

    expect(body).to include("<strong>Abo Bestellung</strong><br>")
    expect(body).to include("<td>Gewünschte Sprache</td><td>Deutsch</td>")
    expect(body).to include("<td>Ab Ausgabe</td><td>Nächste Ausgabe nach Zahlungseingang</td>")
    expect(body).to include("<td>Preis</td><td>CHF 60.00</td>")

    expect(body).to include("<strong>Deine Angaben</strong><br>")
    expect(body).to include("<td>Geschlecht</td><td>weiblich</td>")
    expect(body).to include("<td>Vorname</td><td>Edmund</td>")
    expect(body).to include("<td>Nachname</td><td>Hillary</td>")
    expect(body).to include("<td>E-Mail</td><td>e.hillary@hitobito.example.com</td>")
    expect(body).to include("<td>Adresszusatz</td><td>1A</td>")
    expect(body).to include("<td>Strasse und Nr.</td><td>Ophovenerstrasse 79a</td>")
    expect(body).to include("<td>Postfach</td><td>123</td>")
    expect(body).to include("<td>PLZ</td><td>2843</td>")
    expect(body).to include("<td>Ort</td><td>Neu Carlscheid</td>")
    expect(body).to include("<td>Land</td><td>CH</td>")
    expect(body).to include("<td>Geburtsdatum</td><td>01.01.2000</td>")
    # rubocop:todo Layout/LineLength
    expect(body).to include('Ich habe die <a href="https://www.sac-cas.ch/de/meta/agb/die-alpen/">AGB</a> ' \
      "gelesen und stimme diesen zu.<br>")
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    expect(body).to include('Ich habe die <a href="https://www.sac-cas.ch/de/meta/datenschutz">Datenschutzerklärung</a> ' \
      "gelesen und stimme diesen zu.<br>")
    # rubocop:enable Layout/LineLength
    expect(body).to include("Die Rechnung wird dir in einer separaten E-Mail zugestellt.")
    expect(body).not_to include "Ich möchte den SAC-Newsletter abonnieren."
  end

  it "uses person language to localize message" do
    person.update(language: :fr)
    custom_content.update!(locale: :fr, label: "fr", subject: "Acceptee",
      body: custom_content.body.to_s)
    expect(mail.subject).to eq("Acceptee")
  end

  describe "optional newsletter line" do
    it "includes newsletter statement" do
      body = described_class.confirmation(person, group, true).body.to_s
      expect(body).to include "Ich möchte den SAC-Newsletter abonnieren."
    end

    it "excludes newsletter statement" do
      body = described_class.confirmation(person, group, false).body.to_s
      expect(body).not_to include "Ich möchte den SAC-Newsletter abonnieren."
    end
  end
end
