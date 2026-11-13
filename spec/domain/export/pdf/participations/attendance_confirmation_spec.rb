# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::Pdf::Participations::AttendanceConfirmation do
  include PdfHelpers

  let(:event) { events(:top_course) }
  let(:person) { people(:mitglied) }
  let(:participation) { event_participations(:top_mitglied) }

  let(:pdf) { subject.render }
  let(:text) { PDF::Inspector::Text.analyze(pdf).strings.join(" ").squish }

  subject { described_class.new(participation) }

  before do
    event.update!(name: "Erste-Hilfe-Kurs", location: "Kandersteg",
      description: "Kursbeschreibung auf Deutsch", description_fr: "Description en français")
    participation.update_columns(price: 700)
    travel_to(Time.zone.local(2026, 11, 13, 10))
  end

  it "renders address, course details, description and print date" do
    expect(text).to include("Edmund Hillary Ophovenerstrasse 79a 2843 Neu Carlscheid")
    expect(text).to include("KURSBESTÄTIGUNG")
    expect(text).to include("den Kurs Erste-Hilfe-Kurs 10 des Schweizer Alpen-Club SAC besucht hat.")
    expect(text).to include("Kursort: Kandersteg")
    expect(text).to include("Kursdatum: 1. März bis 10. April 2023")
    expect(text).to include("Kursnummer: 10")
    expect(text).to include("Kurspreis: CHF 700.00")
    expect(text).to include("Kursbeschreibung auf Deutsch")
    expect(text).to include("Schweizer Alpen-Club SAC Monbijoustrasse 61, Postfach, CH-3000 Bern 14 " \
      "+41 31 370 18 18, alpin@sac-cas.ch")
    expect(text).to include("Bern, 13.11.2026")
  end

  it "renders texts and logo at positions of template" do
    expect(text_with_position).to eq [
      [74, 782, "www.sac-cas.ch"],
      [74, 653, "Edmund Hillary"],
      [74, 640, "Ophovenerstrasse 79a"],
      [74, 627, "2843 Neu Carlscheid"],
      [74, 563, "KURSBESTÄTIGUNG"],
      [74, 502, "Hiermit bestätigen wir, dass"],
      [74, 481, "Edmund Hillary"],
      [74, 461, "den Kurs "],
      [116, 461, "Erste-Hilfe-Kurs 10"],
      [206, 461, " des Schweizer Alpen-Club SAC besucht hat."],
      [74, 440, "Kursort:"],
      [113, 440, " Kandersteg"],
      [74, 426, "Kursdatum:"],
      [129, 426, " 1. März bis 10. April 2023"],
      [74, 413, "Kursnummer:"],
      [139, 413, " 10"],
      [74, 400, "Kurspreis:"],
      [123, 400, " CHF 700.00"],
      [74, 374, "Kursbeschreibung auf Deutsch"],
      [74, 349, "Diese Kursbestätigung dient als Nachweis über den Besuch des oben genannten Kurses."],
      [74, 308, "Sportliche Grüsse"],
      [74, 295, "Schweizer Alpen-Club SAC"],
      [74, 254, "Kursadministration"],
      [74, 61, "Schweizer Alpen-Club SAC"],
      [74, 49, "Monbijoustrasse 61, Postfach, CH-3000 Bern 14"],
      [74, 36, "+41 31 370 18 18, alpin@sac-cas.ch"],
      [477, 24, "Bern, 13.11.2026"]
    ]
    expect(image_positions).to eq [
      {x: 378.28709, y: 732.39, width: 397, height: 166, displayed_width: 72651.0,
       displayed_height: 12699.0}
    ]
  end

  it "renders foreign country" do
    person.update!(country: "DE", zip_code: "10115", town: "Berlin")
    expect(text).to include("10115 Berlin DE")
  end

  it "renders price of zero when participation has no price" do
    participation.update_columns(price: nil)
    expect(text).to include("Kurspreis: CHF 0.00")
  end

  describe "course dates" do
    before { event.dates.destroy_all }

    it "renders single date for one day course" do
      event.dates.create!(start_at: Time.zone.local(2025, 10, 31, 8))
      expect(text).to include("Kursdatum: 31. Oktober 2025")
    end

    it "renders full start date if course spans new year" do
      event.dates.create!(start_at: Time.zone.local(2025, 12, 30), finish_at: Time.zone.local(2026, 1, 2))
      expect(text).to include("Kursdatum: 30. Dezember 2025 bis 2. Januar 2026")
    end
  end

  describe "#locale" do
    def locale_for(course_language, person_language)
      participation.event.language = course_language
      participation.person.language = person_language
      described_class.new(participation).locale
    end

    it "uses course language" do
      expect(locale_for("fr", "de")).to eq :fr
      expect(locale_for("it", "de")).to eq :it
      expect(locale_for("de", "fr")).to eq :de
    end

    it "uses person language for bilingual course if it is one of the course languages" do
      expect(locale_for("de_fr", "fr")).to eq :fr
      expect(locale_for("de_fr", "de")).to eq :de
    end

    it "falls back to first course language for bilingual course" do
      expect(locale_for("de_fr", "it")).to eq :de
    end
  end

  it "renders description in course language" do
    event.update_columns(language: "fr")
    expect(text).to include("Description en français")
  end

  it "#filename contains event name and person name" do
    expect(subject.filename).to eq "Teilnahmebestaetigung_Erste-Hilfe-Kurs_Edmund_Hillary.pdf"
  end
end
