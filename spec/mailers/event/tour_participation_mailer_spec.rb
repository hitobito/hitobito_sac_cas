# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::TourParticipationMailer do
  let(:section) { groups(:bluemlisalp) }
  let(:person) { people(:mitglied) }
  let(:event) { events(:section_tour) }
  let(:participation) { Fabricate(:event_participation, event:, participant: person) }

  before do
    CustomContent.init_section_specific_contents(section)
  end

  context "applied" do
    let(:mail) { described_class.confirmation(participation, described_class::APPLIED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Auf Warteliste zur Tour Bundstock")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Aktuell sind alle Plätze belegt, weshalb wir dich auf die Warteliste genommen haben.",
        "Bei Fragen kannst du dich jederzeit an   wenden (, , ).",
        "Bergsportliche Grüsse,<br>SAC Blüemlisalp",
        "<dt>Kommentar</dt><dd>(keine)</dd>"
      )
      expect(mail.body.to_s).not_to include(
        "Anmeldefenster",
        "Unterzielgruppe(n)"
      )
    end

    it "contains placeholder values" do
      contact = people(:familienmitglied)
      contact.phone_numbers.create!(number: "079 123 45 67", label: "mobile")
      event.update!(
        state: "draft", # required to set other values
        contact: contact,
        application_opening_at: "1.11.2022",
        application_closing_at: "15.12.2022",
        disciplines: event_disciplines(:skihochtour, :wanderweg, :bergtour),
        target_groups: event_target_groups(:familien, :senioren_b),
        description: "Wichtige Infos\nauf mehreren Zeilen",
        additional_info: nil
      )
      event.dates.first.update!(finish_at: "6.2.2023")
      event.reload

      expect(mail.body.to_s).to include(
        "<dt>Daten</dt><dd>Sa 04.02.2023 07:30 - Mo 06.02.2023</dd>",
        "<dt>Anmeldefenster</dt><dd>01.11.2022 - 15.12.2022</dd>",
        "<dt>Kalendereintrag (ics)</dt><dd><a href=\"http://test.host/groups/#{section.id}/events/#{event.id}.ics\">Herunterladen</a></dd>",
        "<dt>Zielgruppe(n)</dt><dd>Senioren, Familien (FaBe)</dd>",
        "<dt>Unterzielgruppe(n)</dt><dd>Senioren B</dd>",
        "<dt>Disziplin(en)</dt><dd>Wandern, Hochtouren</dd>",
        "<dt>Unterdisziplin(en)</dt><dd>Wanderweg, Bergtour, Skihochtouren</dd>",
        "<dt>Merkmal(e)</dt><dd>Anreise mit ÖV, Exkursion</dd>",
        "<dt>Konditionelle Anforderung</dt><dd>B - wenig anstrengend</dd>",
        "<dt>Technische Anforderung(en)</dt><dd>T3, T4</dd>",
        "<dt>Beschreibung</dt><dd>Wichtige Infos<br/>auf mehreren Zeilen</dd>",
        "Bei Fragen kannst du dich jederzeit an Tenzing Norgay wenden " \
        "(#{contact.id}, +41 79 123 45 67, t.norgay@hitobito.example.com)."
      )

      expect(mail.body.to_s).not_to include(
        "Zusatzinfo"
      )
    end
  end

  context "unconfirmed" do
    let(:mail) { described_class.confirmation(participation, described_class::UNCONFIRMED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Anmeldung zur Tour Bundstock (unbestätigt)")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Es handelt sich hierbei um keine definitive Zusage."
      )
    end
  end

  context "assigned" do
    let(:mail) { described_class.confirmation(participation, described_class::ASSIGNED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Anmeldung zur Tour Bundstock bestätigt")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Gerne teilen wir dir mit, dass deine Anmeldung bestätigt wurde."
      )
    end
  end

  describe "#reject" do
    let(:mail) { described_class.reject(participation) }

    it "sends to email addresses of declined participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Anmeldung zur Tour #{event.name} abgelehnt"
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Leider können wir dich für diese Tour diesmal nicht berücksichtigen."
      )
    end
  end

  describe "#summon" do
    subject { mail.body }

    let(:mail) { described_class.summon(participation) }

    it "sends to email addresses of summoned participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Aufgebot zur Tour #{event.name}"
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Gerne bieten wir dich für die Tour \"#{event.name} (#{event.id})\" auf"
      )
    end
  end

  describe "#canceled" do
    let(:mail) { described_class.canceled(participation) }

    it "sends to email addresses of participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Abmeldung zur Tour #{event.name}"
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Vielen Dank für deine Abmeldung für die Tour \"#{event.name} (#{event.id})\":"
      )
    end
  end
end
