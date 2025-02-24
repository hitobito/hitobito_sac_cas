# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ApplicationConfirmationMailer do
  let(:event) { Fabricate(:sac_open_course, number: 123, application_closing_at: Date.new(2038, 1, 19)) }
  let(:participation) { event.participations.create!(person: people(:mitglied), price: 12.3, price_category: "price_regular") }
  let(:mail) { described_class.confirmation(participation, described_class::APPLIED) }

  before { Group.root.update!(course_admin_email: "admin@example.com") }

  context "applied" do
    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["admin@example.com"])
      expect(mail.subject).to eq("Auf Warteliste gesetzt")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Du wurdest für den Kurs Eventus (Nummer: 123) auf die unbestätigte Warteliste gesetzt.",
        "Anmeldeschluss ist der 19.01.2038.",
        "Preis: 12.30"
      )
    end
  end

  context "unconfirmed" do
    let(:mail) { described_class.confirmation(participation, described_class::UNCONFIRMED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["admin@example.com"])
      expect(mail.subject).to eq("Unbestätigte Kursanmeldung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Du wurdest für den Kurs Eventus (Nummer: #{event.number}) auf die unbestätigte Kursanmeldung gesetzt.",
        "Preis: 12.30"
      )
    end
  end

  context "assigned" do
    let(:mail) { described_class.confirmation(participation, described_class::ASSIGNED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["admin@example.com"])
      expect(mail.subject).to eq("Kursanmeldung bestätigt")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Deine Anmeldung für den Kurs Eventus (Nummer: #{event.number}) wurde bestätigt."
      )
    end
  end

  context "missing information" do
    before { event.questions.create!(admin: true, question: "AHV-Nummer", disclosure: :optional) }

    it "shows a list of missing answers" do
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Für die Teilnahme an diesem Kurs sind die folgenden Nachweise zu erbringen.",
        "<ul><li>AHV-Nummer</li></ul>"
      )
    end
  end

  context "missing price" do
    before { participation.update!(price: nil) }

    it "sends email to participant with empty price" do
      expect(mail.body.to_s).to include("Hallo Edmund,", "Preis: <br>")
    end
  end
end
