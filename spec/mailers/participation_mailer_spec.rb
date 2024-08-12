# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationMailer do
  let(:person) { people(:mitglied) }
  let(:event) {
    Fabricate(:sac_open_course, contact_id: person.id, dates: [
      Fabricate(:event_date, start_at: 1.week.from_now)
    ])
  }
  let(:participation) { Fabricate(:event_participation, event: event, person: person) }
  let(:mail) { Event::ParticipationMailer.confirmation(participation) }

  before do
    Fabricate(:phone_number, contactable: person, public: true)
  end

  subject { mail.parts.first.body }

  describe "#rejection" do
    subject { mail.body }

    let(:mail) { Event::ParticipationMailer.reject(participation) }

    it "sends to email addresses of declined participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Kursablehnung"
    end

    it { is_expected.to match(/Hallo Edmund Hillary/) }
    it { is_expected.to match(/Sie wurden leider für den Kurs Eventus abgelehnt/) }
  end

  describe "#summon" do
    subject { mail.body }

    let(:mail) { Event::ParticipationMailer.summon(participation) }

    it "sends to email addresses of summoned participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Kurs: E-Mail Aufgebot"
    end

    it { is_expected.to match(/Hallo Edmund/) }
    it { is_expected.to match(/Sie wurden für den Kurs Eventus .* aufgeboten/) }

    it "includes the parameters" do
      expect(mail.body).to include(event.to_s)
      expect(mail.body).to include(event.number)
      expect(mail.body).to include("<a href=\"http://test.host/groups/385153371/people/600001\">http://test.host/groups/385153371/people/600001</a>")
      expect(mail.body).to include("<a href=\"http://test.host/groups/385153371/events/#{event.id}\">Eventus (#{event.number})</a>")
      expect(mail.body).to include(event.book_discount_code.to_s)
    end

    context "multiple languages" do
      subject { mail.body }

      before { event.update!(language: "de_fr") }

      it "sends in both languages" do
        is_expected.to include("Détails du cours")
        is_expected.to include("Kursdetails")
      end
    end
  end
end
