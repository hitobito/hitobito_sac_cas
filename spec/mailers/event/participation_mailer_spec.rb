# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationMailer do
  let(:person) { people(:mitglied) }
  let(:event) {
    Fabricate(:sac_open_course, name: "Test Kurs", contact_id: person.id, dates: [
      Fabricate(:event_date, start_at: 1.week.from_now)
    ])
  }
  let(:participation) { Fabricate(:event_participation, event: event, person: person) }
  let(:mail) { Event::ParticipationMailer.confirmation(participation) }

  before do
    Fabricate(:phone_number, contactable: person, public: true)
    event.groups.first.course_admin_email = "kurse@sac-cas.ch"
  end

  subject { mail.parts.first.body }

  describe "#rejection" do
    subject { mail.body }

    let(:mail) { Event::ParticipationMailer.reject(participation) }

    it "sends to email addresses of declined participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq "Kursablehnung"
    end

    it { is_expected.to match(/Hallo Edmund Hillary/) }
    it { is_expected.to match(/Sie wurden leider für den Kurs Test Kurs abgelehnt/) }
  end

  describe "#summon" do
    subject { mail.body }

    let(:mail) { Event::ParticipationMailer.summon(participation) }

    it "sends to email addresses of summoned participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Kurs: E-Mail Aufgebot"
    end

    it { is_expected.to match(/Hallo Edmund/) }
    it { is_expected.to match(/Sie wurden für den Kurs Test Kurs .* aufgeboten/) }

    it "includes the parameters" do
      expect(mail.body).to include(event.to_s)
      expect(mail.body).to include(event.number)
      expect(mail.body).to include("<a href=\"http://test.host/groups/385153371/people/600001\">http://test.host/groups/385153371/people/600001</a>")
      expect(mail.body).to include("<a href=\"http://test.host/groups/385153371/events/#{event.id}\">Test Kurs (#{event.number})</a>")
      expect(mail.body).to include(event.book_discount_code.to_s)
    end

    context "course langauge" do
      subject { mail.body }

      before do
        event.update!(language: "fr")
        I18n.with_locale(:fr) do
          event.update!(name: "Course test")
        end
      end

      it "is used for email" do
        expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
        expect(mail.subject).to eq("Convocation au cours")
        is_expected.to match(/Vous avez été convoqué\(e\) pour le cours Course test \(Numéro: .*\).<br><br>/)
        is_expected.to include("Détails du cours")
        # placeholders are also translated
        is_expected.to include("Course test")
      end
    end

    context "multiple languages" do
      subject { mail.body }

      before do
        event.update!(language: "de_fr")
        I18n.with_locale(:fr) do
          event.update!(name: "Course test")
        end
      end

      it "sends in both languages" do
        expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
        expect(mail.subject).to eq("Kurs: E-Mail Aufgebot / Convocation au cours")
        is_expected.to match(/Sie wurden für den Kurs Test Kurs \(Nummer: .*\) aufgeboten.<br><br>/)
        is_expected.to match(/Vous avez été convoqué\(e\) pour le cours Course test \(Numéro: .*\).<br><br>/)
        is_expected.to include("Kursdetails")
        is_expected.to include("Détails du cours")
        is_expected.to include(MultiLanguageMailer::LANGUAGE_SEPARATOR)
        # placeholders are also translated
        is_expected.to include("Test Kurs")
        is_expected.to include("Course test")
      end
    end
  end
end
