# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ParticipationMailer do
  let(:person) { people(:mitglied) }
  let(:event) do
    Fabricate(:event, name: "Test Kurs", contact_id: person.id, dates: [
      Fabricate(:event_date, start_at: 1.week.from_now)
    ])
  end
  let(:participation) { Fabricate(:event_participation, event:, participant: person, active: true) }

  describe "#confirmation" do
    let(:mail) { Event::ParticipationMailer.confirmation(participation) }

    it "sends to email addresses of confirmed participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Bestätigung der Anmeldung"
      body = mail.parts.first
      expect(body.content_type).to eq("text/html; charset=UTF-8")
      expect(body.to_s).to include("Hallo Edmund")
      expect(body.to_s).to include("folgenden Anlass angemeldet:")
      expect(body.to_s).to include("Test Kurs")
    end
  end
end
