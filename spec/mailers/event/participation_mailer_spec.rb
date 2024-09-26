# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

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
    let(:mail) { Event::ParticipationMailer.reject(participation) }

    it "sends to email addresses of declined participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq "Kursablehnung"
      expect(mail.body.to_s).to include("Hallo Edmund,")
      expect(mail.body.to_s).to include("Du wurdest leider für den Kurs Test Kurs abgelehnt")
    end
  end

  describe "#summon" do
    subject { mail.body }

    let(:mail) { Event::ParticipationMailer.summon(participation) }

    it "sends to email addresses of summoned participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Kurs: E-Mail Aufgebot"
      expect(mail.body.to_s).to include("Hallo Edmund,")
      expect(mail.body.to_s).to include("Du wurdest für den Kurs Test Kurs (Nummer: #{event.number}) aufgeboten")
    end

    it "includes the parameters" do
      expect(mail.body).to include(event.to_s)
      expect(mail.body).to include(event.number)
      expect(mail.body).to include("<a href=\"http://test.host/groups/385153371/people/600001\">http://test.host/groups/385153371/people/600001</a>")
      expect(mail.body).to include("<a href=\"http://test.host/groups/385153371/events/#{event.id}\">Test Kurs (#{event.number})</a>")
      expect(mail.body).to include(event.book_discount_code.to_s)
    end

    context "course language" do
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
      before do
        event.update!(language: "de_fr")
        I18n.with_locale(:fr) do
          event.update!(name: "Course test")
        end
      end

      it "sends in both languages" do
        expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
        expect(mail.subject).to eq("Kurs: E-Mail Aufgebot / Convocation au cours")
        is_expected.to match(/Du wurdest für den Kurs Test Kurs \(Nummer: .*\) aufgeboten.<br><br>/)
        is_expected.to match(/Vous avez été convoqué\(e\) pour le cours Course test \(Numéro: .*\).<br><br>/)
        is_expected.to include("Kursdetails", "Détails du cours")
        is_expected.to include(MultilingualMailer::LANGUAGE_SEPARATOR)
        # placeholders are also translated
        is_expected.to include("Test Kurs", "Course test")
        is_expected.not_to include("&lt;")
      end
    end

    context "course languages that dont have custom content" do
      before { event.update!(language: "it") }

      it "sends in default language" do
        expect(mail.subject).to eq("Kurs: E-Mail Aufgebot")
        expect(mail.body).not_to include("<div id='content'></div>")
      end
    end

    context "xss" do
      it "does not include wrongly encoded tags" do
        is_expected.not_to include("&lt;")
      end

      it "sanitizes html tags" do
        event.update!(name: "Test<script>alert('XSS')</script>kurs")
        is_expected.to include("Test&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;kurs")
        is_expected.not_to include("<script>")
      end

      it "removes tags inside event" do
        event.update!(name: "Test<br>kurs")
        is_expected.to include("Test&lt;br&gt;kurs")
      end

      it "sanitizes html tags in event name" do
        event.update!(name: "Event<script>alert('XSS')</script>Name")
        is_expected.to include("Event&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;Name")
        is_expected.not_to include("<script>")
      end

      it "sanitizes html tags in event description" do
        event.update!(description: "Description<script>alert('XSS')</script>Text")
        is_expected.to include("Description&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;Text")
        is_expected.not_to include("<script>")
      end

      it "sanitizes html tags in event location" do
        event.update!(location: "Location<script>alert('XSS')</script>Text")
        is_expected.to include("Location&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;Text")
        is_expected.not_to include("<script>")
      end

      it "sanitizes html tags in event contact" do
        person = people(:mitglied)
        person.first_name = "Contact<script>alert('XSS')</script>Text"
        event.update!(contact: person)
        is_expected.to include("Contact&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;Text")
        is_expected.not_to include("<script>")
      end
    end
  end
end
