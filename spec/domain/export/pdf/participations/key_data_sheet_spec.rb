# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::Pdf::Participations::KeyDataSheet do
  include PdfHelpers

  let(:event) { events(:top_course) }
  let(:group) { event.groups.first }
  let(:now) { Time.zone.now }

  let(:person) { people(:mitglied) }
  let!(:participation) do
    Fabricate(event_role_type.name.to_sym,
      participation: event_participations(:top_mitglied)).participation.tap { _1.reload }
  end

  let(:pdf) { subject.render }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf) }
  let(:page_analysis) { PDF::Inspector::Page.analyze(pdf) }
  let(:year) { Time.zone.now.year }

  subject { described_class.new(participation) }

  before do
    event.update!(location: "Berghotel Schwarenbach\n3752 Kandersteg")
    travel_to(now)
  end

  let(:texts) {
    [
      [70, 776, "SAC Kurse / Touren #{year}"],
      [70, 737, "Eckdatenblatt"],
      [70, 712, "Hallo Edmund"],
      [70, 688, "Nachfolgend senden wir dir die wichtigsten Informationen:"],
      [75, 656, "Veranstaltungs-Nr."],
      [195, 656, "10"],
      [75, 635, "Bezeichnung / Titel"],
      [195, 635, "Tourenleiter/in 1 Sommer"],
      [75, 615, "Angebot / Stufe"],
      [195, 615, "Einstiegskurs"],
      [75, 594, "Leitung"],
      [195, 594, "Edmund Hillary"],
      [75, 573, "Durchführungsdatum"],
      [195, 573, "01.03.2023 - "],
      [195, 563, "03.04.2023 - 10.04.2023"],
      [75, 542, "Durchführungsort"],
      [195, 543, "Berghotel Schwarenbach"],
      [195, 532, "3752 Kandersteg"],
      [75, 512, "Unterkunft"],
      [195, 512, "Wird reserviert durch SAC"],
      [75, 491, "Unterkunft Budget"],
      [195, 491, "Pro Person / Nacht mit Halbpension"],
      [75, 470, "Unterkunft Kategorie"],
      [195, 470, "ohne Übernachtung"],
      [75, 449, "Durchführungssprache"],
      [195, 450, "Deutsch"],
      [75, 429, "Inhalt / Programm"],
      [195, 429, "Gemäss Stoffprogramm Kurse (falls vorhanden) oder Tourenprogramm"],
      [75, 408, "Teilnehmeranforderungen"],
      [195, 408, "Gemäss Ausschreibung SAC Kurse / Touren"],
      [75, 387, "Detailprogramm"],
      [75, 377, "Teilnehmer Kurse"],
      [195, 387, "Wird von der Geschäftsstelle 8 Wochen vor Beginn per Mail bei der Leitung"],
      [195, 377, "eingefordert."],
      [75, 356, "Detailprogramm"],
      [75, 345, "Teilnehmer Touren"],
      [195, 356,
        "Wird von Geschäftsstelle erstellt und spätestens 6 Wochen vor Beginn hinterlegt."],
      [75, 324, "Anmeldeschluss"],
      [195, 325, event.application_closing_at.to_date.strftime("%d.%m.%Y")],
      [75, 304, "Minimale Teilnehmerzahl"],
      [75, 283, "Maximale Teilnehmerzahl"],
      [75, 262, "Durchführung - ja/nein?"],
      [195, 263, "Entscheid wird gestützt auf Anzahl Anmeldungen beim Anmeldeschluss gemeinsam"],
      [195, 252, "gefällt."],
      [75, 232, "Durchführung – Absage"],
      [195, 232, "Bitte Klassenlehrer und Unterkunft informieren"],
      [75, 211, "Ideale Klassengrösse"],
      [75, 190, "Maximale Klassengrösse"],
      [75, 169, "Klassenlehrer"],
      [195, 170,
        "Leitung verpflichtet gem. max. Teilnehmerzahl im Voraus die Klassenlehrer - bitte im"],
      [195, 159,
        "Detailprogramm für Kurse aufführen und für Touren per Mail an Geschäftsstelle senden."],
      [70, 40,
        # rubocop:todo Layout/LineLength
        "Schweizer Alpen-Club SAC, Monbijoustrasse 61, Postfach, CH-3000 Bern 14, +41 31 370 18 43/44, alpin@sac-cas.ch"]
      # rubocop:enable Layout/LineLength
    ]
  }

  let(:expected_logo_position) {
    {x: 380.28, y: 732.89, width: 721, height: 301, displayed_width: 122570.0,
     displayed_height: 21371.0}
  }

  context "course compensation categories of kind day and flat" do
    before do
      event_start_at = event.dates.order(start_at: :asc).first.start_at
      day_category = event.kind.course_compensation_categories.create!(
        kind: :day,
        short_name: "Tageshonorar",
        name_leader: "Tageshonorar Kursleiter",
        name_assistant_leader: "Tageshonorar Klassenleiter"
      )
      day_category.course_compensation_rates.create!(
        rate_leader: 100,
        rate_assistant_leader: 50,
        valid_from: event_start_at - 10.days
      )

      flat_category = event.kind.course_compensation_categories.create!(
        kind: :flat,
        short_name: "Kurspauschale",
        name_leader: "Pauschale Kursleiter",
        name_assistant_leader: "Pauschale Klassenleiter"
      )
      flat_category.course_compensation_rates.create!(
        rate_leader: 60,
        rate_assistant_leader: 40,
        valid_from: event_start_at - 10.days
      )

      day_category_without_valid_rate = event.kind.course_compensation_categories.create!(
        kind: :day,
        short_name: "Tageshonorar ohne validen Ansatz",
        name_leader: "Tageshonorar ohne validen Ansatz Kursleiter",
        name_assistant_leader: "Tageshonorar ohne validen Ansatz Klassenleiter"
      )
      day_category_without_valid_rate.course_compensation_rates.create!(
        rate_leader: 100,
        rate_assistant_leader: 50,
        valid_from: event_start_at + 10.days
      )

      flat_category_without_valid_rate = event.kind.course_compensation_categories.create!(
        kind: :flat,
        short_name: "Kurspauschale ohne validen Ansatz",
        name_leader: "Pauschale ohne validen Ansatz Kursleiter",
        name_assistant_leader: "Pauschale ohne validen Ansatz Klassenleiter"
      )
      flat_category_without_valid_rate.course_compensation_rates.create!(
        rate_leader: 60,
        rate_assistant_leader: 40,
        valid_from: event_start_at + 10.days
      )
    end

    context "as leader" do
      let(:event_role_type) { Event::Course::Role::Leader }

      it "renders" do
        expected_postions = [
          [195, 573, "Tageshonorar Kursleiter"],
          [335, 573, "1"],
          [355, 573, "Tag"],
          [435, 573, "à CHF"],
          [485, 573, "100.00"],
          [195, 553, "Pauschale Kursleiter"],
          [335, 553, "1"],
          [355, 553, "Pauschale"],
          [435, 553, "à CHF"],
          [485, 553, "60.00"]
        ]

        find_matches(expected_postions)
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Tageshonorar ohne validen Ansatz")
        expect(analyzer.show_text).to_not include("Pauschale ohne validen Ansatz")
      end
    end

    context "as assistant leader" do
      let(:event_role_type) { Event::Course::Role::AssistantLeader }

      it "renders" do
        expected_postions = [
          [195, 573, "Tageshonorar Klassenleiter"],
          [335, 573, "1"],
          [355, 573, "Tag"],
          [435, 573, "à CHF"],
          [485, 573, "50.00"],
          [195, 553, "Pauschale Klassenleiter"],
          [335, 553, "1"],
          [355, 553, "Pauschale"],
          [435, 553, "à CHF"],
          [485, 553, "40.00"]
        ]

        find_matches(expected_postions)
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Tageshonorar ohne validen Ansatz")
        expect(analyzer.show_text).to_not include("Pauschale ohne validen Ansatz")
      end
    end
  end

  context "course compensation categories of kind budget" do
    before do
      event_start_at = event.dates.order(start_at: :asc).first.start_at
      budget_category = event.kind.course_compensation_categories.create!(
        kind: :budget,
        short_name: "Anreise",
        name_leader: "Anreise Kursleiter",
        name_assistant_leader: "Anreise Klassenleiter"
      )
      budget_category.course_compensation_rates.create!(
        rate_leader: 30,
        rate_assistant_leader: 50,
        valid_from: event_start_at - 10.days
      )

      budget_category_without_valid_rate = event.kind.course_compensation_categories.create!(
        kind: :budget,
        short_name: "Anreise ohne validen Ansatz",
        name_leader: "Anreise Kursleiter ohne validen Ansatz",
        name_assistant_leader: "Anreise Klassenleiter ohne validen Ansatz"
      )
      budget_category_without_valid_rate.course_compensation_rates.create!(
        rate_leader: 30,
        rate_assistant_leader: 50,
        valid_from: event_start_at + 10.days
      )
    end

    context "as leader" do
      let(:event_role_type) { Event::Course::Role::Leader }

      it "renders" do
        find_matches([
          [75, 491, "Unterkunft Budget"],
          [195, 491, "Pro Person / Nacht mit Halbpension"],
          [195, 470, "Anreise Kursleiter"],
          [435, 470, "CHF"],
          [485, 470, "30.00"]
        ])
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Anreise ohne validen Ansatz")
      end
    end

    context "as assistant leader" do
      let(:event_role_type) { Event::Course::Role::AssistantLeader }

      it "renders" do
        find_matches([
          [75, 491, "Unterkunft Budget"],
          [195, 491, "Pro Person / Nacht mit Halbpension"],
          [195, 470, "Anreise Klassenleiter"],
          [435, 470, "CHF"],
          [485, 470, "50.00"]
        ])
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Anreise ohne validen Ansatz")
      end
    end
  end

  context "as leader" do
    let(:event_role_type) { Event::Course::Role::Leader }

    it "sanitizes filename" do
      # rubocop:todo Layout/LineLength
      expect(subject.filename).to eq "Eckdatenblatt_Kursleitung_Edmund_Hillary_#{now.strftime("%Y_%m_%d_%H%M")}.pdf"
      # rubocop:enable Layout/LineLength
    end

    context "text" do
      it "renders" do
        find_matches(texts)
      end

      it "renders logo" do
        expect(image_positions).to match_array [expected_logo_position]
      end

      it "has logo" do
        sections = subject.send(:sections)
        logo_path = sections[0].logo_path
        expect(image_included_in_images?(logo_path)).to be(true)
      end
    end

    context "with multiple leaders" do
      let!(:additional_leaders) do
        [people(:familienmitglied), people(:familienmitglied2),
          people(:familienmitglied_kind)].map do
          participation = event.participations.where(participant: _1).first
          participation ||= Fabricate(:event_participation, event: event)
          Fabricate(Event::Course::Role::Leader.name.to_sym,
            participation: participation)
          participation.reload

          participation.person
        end
      end

      it "renders only the selected leader" do
        expect(analyzer.show_text[11]).to eq(person.full_name)
      end
    end

    context "reserve_accommodation" do
      it "renders sac accommodation if true" do
        event.update!(reserve_accommodation: true)
        text = analyzer.show_text[19]
        expect(text).to eq("Wird reserviert durch SAC")
      end

      it "renders event_specific if false" do
        event.update!(reserve_accommodation: false)
        text = analyzer.show_text[19]
        expect(text).to eq("Wird reserviert durch Kursleitung")
      end
    end
  end

  context "as assistant leader" do
    let(:event_role_type) { Event::Course::Role::AssistantLeader }

    it "sanitizes filename" do
      # rubocop:todo Layout/LineLength
      expect(subject.filename).to eq "Eckdatenblatt_Klassenleitung_Edmund_Hillary_#{now.strftime("%Y_%m_%d_%H%M")}.pdf"
      # rubocop:enable Layout/LineLength
    end

    context "text" do
      it "renders" do
        find_matches(texts)
      end

      it "renders logo" do
        expect(image_positions).to match_array [expected_logo_position]
      end

      it "has logo" do
        sections = subject.send(:sections)
        logo_path = sections[0].logo_path
        expect(image_included_in_images?(logo_path)).to be(true)
      end
    end

    context "with multiple leaders" do
      let!(:additional_leaders) do
        [people(:familienmitglied), people(:familienmitglied2),
          people(:familienmitglied_kind)].map do
          participation = event.participations.where(participant: _1).first
          participation ||= Fabricate(:event_participation, event: event)
          Fabricate(Event::Course::Role::Leader.name.to_sym,
            participation: participation)
          participation.reload

          participation.person
        end
      end

      it "renders only the selected leader" do
        expect(analyzer.show_text[11]).to eq(person.full_name)
      end
    end
  end

  private

  def extract_image_objects(page_no = 1)
    rendered_pdf = pdf.try(:render) || pdf
    io = StringIO.new(rendered_pdf)

    PDF::Reader.open(io) do |reader|
      page = reader.page(page_no)

      # Extract all XObjects of type :Image from the page
      page.xobjects.select { |_, obj| obj.hash[:Subtype] == :Image }.to_a.map { |item|
        Digest::MD5.hexdigest(item[1].data)
      }
    end
  end

  def image_included_in_images?(image_path)
    image_data = Digest::MD5.hexdigest(File.binread(image_path))
    extract_image_objects.include?(image_data)
  end

  def find_potential_matches(actual_positions, expected_position_text)
    actual_positions.select do |x, y, text|
      text.include?(expected_position_text)
    end.map { |x, y, text| "#{text} at x: #{x}, y: #{y}" }
  end

  def find_matches(expected_positions, actual_positions = text_with_position(analyzer))
    expected_positions.each do |x, y, text|
      expect(actual_positions).to(include([x, y, text]),
        "expected #{x}, #{y} to be #{text}. \
        potential matches: #{find_potential_matches(actual_positions, text).join("\n")}")
    end
  end
end
