# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::TourMailer do
  let(:section) { groups(:bluemlisalp) }
  let(:person) { people(:mitglied) }
  let(:event) { events(:section_tour) }

  before do
    CustomContent.init_section_specific_contents(section)
  end

  describe "publication" do
    let(:mail) { described_class.publication(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Publikation der Tour #{event.name}")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Gerne informieren wir dich, dass die Tour \"#{event.name} (#{event.id})\" heute publiziert wurde:",
        "Bergsportliche Grüsse,<br>SAC Blüemlisalp"
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

  describe "publication_subito" do
    let(:mail) { described_class.publication_subito(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Publikation der Subito-Tour #{event.name}")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Gerne informieren wir dich, dass die Subito-Tour \"#{event.name} (#{event.id})\" heute publiziert wurde:"
      )
    end
  end

  describe "participation_summon" do
    let(:mail) { described_class.participation_summon(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Aufgebot zur Tour #{event.name}")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Gerne bieten wir dich für die Tour \"#{event.name} (#{event.id})\" auf:"
      )
    end
  end

  describe "participation_reject" do
    let(:mail) { described_class.participation_reject(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Anmeldung zur Tour #{event.name} abgelehnt")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Leider können wir dich für diese Tour diesmal nicht berücksichtigen. " \
          "Wir wissen dein Interesse sehr zu schätzen und hoffen, dich bei einer " \
          "unserer nächsten Touren dabei zu haben."
      )
    end
  end

  describe "back_to_draft" do
    let(:mail) { described_class.back_to_draft(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Statuswechsel der Tour #{event.name} zurück zu Entwurf")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "die Tour \"#{event.name} (#{event.id})\" in den Status \"Entwurf\" verschoben:"
      )
    end
  end

  describe "back_to_approved" do
    let(:mail) { described_class.back_to_approved(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Statuswechsel der Tour #{event.name} zurück zu Freigegeben")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "die Tour \"#{event.name} (#{event.id})\" in den Status \"Freigegeben\" verschoben:"
      )
    end
  end

  describe "back_to_published" do
    let(:mail) { described_class.back_to_published(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Statuswechsel der Tour #{event.name} zurück zu Publiziert")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "die Tour \"#{event.name} (#{event.id})\" in den Status \"Publiziert\" verschoben:"
      )
    end
  end

  describe "back_to_ready" do
    let(:mail) { described_class.back_to_ready(event, person) }

    it "sends email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Statuswechsel der Tour #{event.name} zurück zu Vorbereitung abgeschlossen")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "die Tour \"#{event.name} (#{event.id})\" in den Status \"Vorbereitung abgeschlossen\" verschoben:"
      )
    end
  end

  describe "#closing" do
    let(:mail) { described_class.closing(event, person) }

    it "sends to email addresses of participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Abschluss der Tour #{event.name}"
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Vielen Dank für deine Teilnahme an der Tour \"#{event.name} (#{event.id})\":"
      )
    end
  end

  describe "#canceled_minimum_participants" do
    let(:mail) { described_class.canceled_minimum_participants(event, person) }

    it "sends to email addresses of participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Absage der Tour #{event.name}"
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Vielen Dank für deine Anmeldung zur Tour \"#{event.name} (#{event.id})\":",
        "Leider müssen wir dir mitteilen, dass die Tour abgesagt wurde. Grund dafür sind zuwenig Teilnehmende."
      )
    end
  end

  describe "#canceled_no_leader" do
    let(:mail) { described_class.canceled_no_leader(event, person) }

    it "sends to email addresses of participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Absage der Tour #{event.name}"
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Vielen Dank für deine Anmeldung zur Tour \"#{event.name} (#{event.id})\":",
        "Leider müssen wir dir mitteilen, dass die Tour abgesagt wurde. Grund dafür ist ein Ausfall der Tourenleitung."
      )
    end
  end

  describe "#canceled_weather" do
    let(:mail) { described_class.canceled_weather(event, person) }

    it "sends to email addresses of participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Absage der Tour #{event.name}"
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{person.id})",
        "Vielen Dank für deine Anmeldung zur Tour \"#{event.name} (#{event.id})\":",
        "Leider müssen wir dir mitteilen, dass die Tour abgesagt wurde. Grund dafür ist schlechtes Wetter."
      )
    end
  end
end
