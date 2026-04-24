# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::CourseParticipationMailer do
  let(:person) { people(:mitglied) }
  let(:event) do
    Fabricate(:sac_open_course,
      name: "Test Kurs",
      number: 123,
      contact_id: person.id,
      application_closing_at: Date.new(2038, 1, 19),
      dates: [Fabricate(:event_date, start_at: 1.week.from_now)])
  end
  let(:participation) do
    Fabricate(:event_participation,
      event:,
      participant: person,
      price: 12.3,
      price_category: "price_regular")
  end

  before do
    Fabricate(:phone_number, contactable: person, public: true)
    Group.root.update!(course_admin_email: "kurse@sac-cas.ch")
  end

  context "applied" do
    let(:mail) { described_class.confirmation(participation, described_class::APPLIED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq("Auf Warteliste gesetzt")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Du wurdest für den Kurs Test Kurs (Nummer: 123) auf die unbestätigte Warteliste gesetzt.",
        "Anmeldeschluss ist der 19.01.2038.",
        "Preis: 12.30"
      )
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

  context "unconfirmed" do
    let(:mail) { described_class.confirmation(participation, described_class::UNCONFIRMED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq("Unbestätigte Kursanmeldung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Du wurdest für den Kurs Test Kurs (Nummer: #{event.number}) auf die unbestätigte Kursanmeldung gesetzt.",
        "Preis: 12.30"
      )
    end
  end

  context "assigned" do
    let(:mail) { described_class.confirmation(participation, described_class::ASSIGNED) }

    it "sends email to participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq("Kursanmeldung bestätigt")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Deine Anmeldung für den Kurs Test Kurs (Nummer: #{event.number}) wurde bestätigt."
      )
    end
  end

  describe "#reject_applied" do
    let(:mail) { described_class.reject_applied(participation) }

    it "sends to email addresses of declined participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq "Kursablehnung"
      expect(mail.body.to_s).to include("Hallo Edmund,")
      expect(mail.body.to_s).to include(
        "Du wurdest leider für den Kurs Test Kurs (Nummer: #{event.number}) abgelehnt"
      )
    end
  end

  describe "#reject_rejected" do
    let(:mail) { described_class.reject_rejected(participation) }

    it "sends to email addresses of declined participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq "Kursablehnung"
      expect(mail.body.to_s).to include("Hallo Edmund,")
      expect(mail.body.to_s).to include(
        "Du wurdest leider für den Kurs Test Kurs (Nummer: #{event.number}) abgelehnt"
      )
    end
  end

  describe "#summon" do
    subject { mail.body }

    let(:mail) { described_class.summon(participation) }

    it "sends to email addresses of summoned participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Kurs: E-Mail Aufgebot"
      expect(mail.body.to_s).to include("Hallo Edmund,")
      expect(mail.body.to_s).to include(
        "Du wurdest für den Kurs Test Kurs (Nummer: #{event.number}) aufgeboten"
      )
    end

    it "includes the parameters" do
      expect(mail.body).to include(event.to_s)
      expect(mail.body).to include(event.number)
      expect(mail.body).to include(
        "<a href=\"http://test.host/groups/385153371/people/600001\">http://test.host/groups/385153371/people/600001</a>"
      )
      expect(mail.body).to include(
        "<a href=\"http://test.host/groups/385153371/events/#{event.id}\">Test Kurs (#{event.number})</a>"
      )
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

    context "course languages that don't have custom content" do
      before { event.update!(language: "it") }

      it "sends in fallback language" do
        expect(mail.subject).to eq("Convocation au cours")
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

  describe "#reminder" do
    let(:mail) { described_class.reminder(participation) }

    before do
      %w[nil_example no_example yes_example].each do |question|
        event.questions.create!(admin: true, question:, disclosure: :optional)
      end
      participation
      event.questions.second.answers.update_all(answer: "no")
      event.questions.third.answers.update_all(answer: "yes")
    end

    it "sends email to participants with missing answers" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.subject).to eq("Fehlende Administrationsangaben")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Für die Teilnahme an diesem Kurs sind die folgenden Nachweise zu erbringen.",
        "nil_example",
        "no_example"
      )
      expect(mail.body.to_s).not_to include("yes_example")
    end
  end

  describe "#canceled" do
    let(:mail) { described_class.canceled(participation) }

    it "sends to email addresses of participant" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Deine Abmeldung für den Kurs Test Kurs (Nummer: #{event.number}) wurde bestätigt."
      )
    end
  end

  describe "#survey" do
    let(:mail) { described_class.survey(participation) }

    it "sends email to participant" do
      event.update!(link_survey: "https://example.com/survey")

      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "wenn du dir einen Moment Zeit nehmen könntest, um an unserer Umfrage teilzunehmen",
        "<a href=\"https://example.com/survey\">https://example.com/survey</a>"
      )
    end
  end

  context "#event_canceled" do
    before { event.update_attribute(:state, :canceled) }

    [["minimum_participants", "Grund dafür ist eine zu geringe Teilnehmerzahl."],
      ["no_leader", "Grund dafür ist der Ausfall der Kursleitung."],
      ["weather", "Grund dafür ist das Wetterrisiko."]].each do |canceled_reason|
      reason, reason_text = canceled_reason
      context reason do
        let(:mail) { described_class.public_send(:"event_canceled_#{reason}", participation) }

        it "sends email to course leader" do
          expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
          expect(mail.bcc).to match_array(["kurse@sac-cas.ch"])
          expect(mail.body.to_s).to include(
            "Hallo Edmund,",
            "Der Kurs Test Kurs (Nummer: 123) wurde leider abgesagt.",
            reason_text
          )
        end
      end
    end
  end
end
