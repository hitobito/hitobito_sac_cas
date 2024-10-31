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
  let(:participation) do
    Fabricate(event_role_type.name.to_sym,
      participation: Fabricate(:event_participation, event: event, person: person)).participation.tap { _1.reload }
  end

  let(:pdf) { subject.render }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf) }
  let(:page_analysis) { PDF::Inspector::Page.analyze(pdf) }
  let(:year) { Time.zone.now.year }

  subject { described_class.new(participation) }

  before { travel_to(now) }

  let(:texts) {
    [
      [70, 776, "SAC Kurse / Touren 2024"],
      [70, 737, "Eckdatenblatt -Kurs-/Tourenleitung"],
      [70, 712, "Hallo Edmund"],
      [70, 688, "Nachfolgend senden wir dir die wichtigsten Informationen:"],
      [75, 656, "Veranstaltungs-Nr."],
      [195, 656, "10"],
      [75, 636, "Bezeichungs / Titel"],
      [195, 636, "Tourenleiter/in 1 Sommer"],
      [75, 615, "Angebot / Stufe"],
      [195, 615, "Einstiegskurs"],
      [75, 595, "Leitung"],
      [195, 595, "Edmund Hillary"],
      [75, 575, "Durchführungsdatum"],
      [195, 575, "01.03.2023 - "],
      [195, 564, "03.04.2023 - 10.04.2023"],
      [75, 544, "Durchführungsort"],
      [75, 523, "Unterkunft"],
      [195, 523, "Wird reserviert durch SAC"],
      [75, 503, "Unterkunft Budget"],
      [195, 503, "Pro Person / Nacht mit Halbpension"],
      [75, 473, "Unterkunft Kategorie"],
      [195, 473, "ohne Übernachtung"],
      [75, 452, "Durchführungssprache"],
      [195, 452, "Deutsch"],
      [75, 432, "Inhalt / Programm"],
      [195, 432, "Gemäss Stoffprogramm Kurse (falls vorhanden) oder Tourenprogramm"],
      [75, 411, "Teilnehmeranforderungen"],
      [195, 411, "Gemäss Ausschreibung SAC Kurse / Touren 2024"],
      [75, 391, "Detailprogramm Teilnehmer"],
      [75, 381, "Kurse"],
      [195, 391, "Wird von der Geschäftsstelle 8 Wochen vor Beginn per Mail / SAC Cloud bei der Leitung"],
      [195, 381, "eingefordert"],
      [75, 360, "Detailprogramm Teilnehmer"],
      [75, 350, "Touren"],
      [195, 360, "Wird von Geschäftsstelle erstellt und spätestens 6 Wochen vor Beginn in der SAC-"],
      [195, 350, "Cloud hinterlegt"],
      [75, 329, "Anmeldeschluss"],
      [75, 309, "Minimale Teilnehmerzahl"],
      [75, 289, "Maximale Teilnehmerzahl"],
      [75, 268, "Durchführung - ja/nein?"],
      [195, 268, "Entscheid wird gestützt auf Anzahl Anmeldungen beim Anmeldeschluss gemeinsam"],
      [195, 258, "gefällt"],
      [75, 237, "Durchführung – Absage"],
      [195, 237, "Bitte Klassenlehrer und Unterkunft informieren"],
      [75, 217, "Ideale Klassengrösse"],
      [75, 196, "Maximale Klassengrösse"],
      [75, 176, "Klassenlehrer"],
      [195, 176, "Leitung verpflichtet gem. max. Teilnehmerzahl im Voraus die Klassenlehrer - bitte im"],
      [195, 166, "Detailprogramm für Kurse aufführen und für Touren per Mail an Geschäftsstelle senden."],
      [70, 40, "Schweizer Alpen-Club SAC, Monbijoustrasse 61, Postfach, CH-3000 Bern 14, +41 31 370 18 43/44, alpin@sac-cas.ch"]
    ]
  }

  let(:expected_logo_position) {
    {x: 380.28, y: 732.89, width: 721, height: 301, displayed_width: 122570.0, displayed_height: 21371.0}
  }

  context "course compensation categories of kind day and flat" do
    before do
      event_start_at = event.dates.order(start_at: :asc).first.start_at
      day_category = event.kind.course_compensation_categories.create!(kind: :day, short_name: "Tageshonorar", name_leader: "Tageshonorar Kursleiter", name_assistant_leader: "Tageshonorar Klassenleiter")
      day_category.course_compensation_rates.create!(rate_leader: 100, rate_assistant_leader: 50, valid_from: event_start_at - 10.days)

      flat_category = event.kind.course_compensation_categories.create!(kind: :flat, short_name: "Kurspauschale", name_leader: "Pauschale Kursleiter", name_assistant_leader: "Pauschale Klassenleiter")
      flat_category.course_compensation_rates.create!(rate_leader: 60, rate_assistant_leader: 40, valid_from: event_start_at - 10.days)

      day_category_without_valid_rate = event.kind.course_compensation_categories.create!(kind: :day, short_name: "Tageshonorar ohne validen Ansatz", name_leader: "Tageshonorar ohne validen Ansatz Kursleiter", name_assistant_leader: "Tageshonorar ohne validen Ansatz Klassenleiter")
      day_category_without_valid_rate.course_compensation_rates.create!(rate_leader: 100, rate_assistant_leader: 50, valid_from: event_start_at + 10.days)

      flat_category_without_valid_rate = event.kind.course_compensation_categories.create!(kind: :flat, short_name: "Kurspauschale ohne validen Ansatz", name_leader: "Pauschale ohne validen Ansatz Kursleiter", name_assistant_leader: "Pauschale ohne validen Ansatz Klassenleiter")
      flat_category_without_valid_rate.course_compensation_rates.create!(rate_leader: 60, rate_assistant_leader: 40, valid_from: event_start_at + 10.days)
    end

    context "as leader" do
      let(:event_role_type) { Event::Role::Leader }

      it "renders" do
        expected_postions = [
          [195, 575, "Tageshonorar Kursleiter"],
          [335, 575, "1"],
          [355, 575, "Tag"],
          [435, 575, "à CHF"],
          [485, 575, "100.0"],
          [195, 554, "Pauschale Kursleiter"],
          [335, 554, "1"],
          [355, 554, "Pauschale"],
          [435, 554, "à CHF"],
          [485, 554, "60.0"]
        ]

        find_matches(expected_postions)
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Tageshonorar ohne validen Ansatz")
        expect(analyzer.show_text).to_not include("Pauschale ohne validen Ansatz")
      end
    end

    context "as assistant leader" do
      let(:event_role_type) { Event::Role::AssistantLeader }

      it "renders" do
        expected_postions = [
          [195, 575, "Tageshonorar Klassenleiter"],
          [335, 575, "1"],
          [355, 575, "Tag"],
          [435, 575, "à CHF"],
          [485, 575, "50.0"],
          [195, 554, "Pauschale Klassenleiter"],
          [335, 554, "1"],
          [355, 554, "Pauschale"],
          [435, 554, "à CHF"],
          [485, 554, "40.0"]
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
      budget_category = event.kind.course_compensation_categories.create!(kind: :budget, short_name: "Anreise", name_leader: "Anreise Kursleiter", name_assistant_leader: "Anreise Klassenleiter")
      budget_category.course_compensation_rates.create!(rate_leader: 30, rate_assistant_leader: 50, valid_from: event_start_at - 10.days)

      budget_category_without_valid_rate = event.kind.course_compensation_categories.create!(kind: :budget, short_name: "Anreise ohne validen Ansatz", name_leader: "Anreise Kursleiter ohne validen Ansatz", name_assistant_leader: "Anreise Klassenleiter ohne validen Ansatz")
      budget_category_without_valid_rate.course_compensation_rates.create!(rate_leader: 30, rate_assistant_leader: 50, valid_from: event_start_at + 10.days)
    end

    context "as leader" do
      let(:event_role_type) { Event::Role::Leader }

      it "renders" do
        expect(text_with_position(analyzer)).to include(
          [75, 503, "Unterkunft Budget"],
          [195, 503, "Pro Person / Nacht mit Halbpension"],
          [195, 483, "Anreise Kursleiter"],
          [435, 483, "CHF"],
          [485, 483, "30.0"]
        )
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Anreise ohne validen Ansatz")
      end
    end

    context "as assistant leader" do
      let(:event_role_type) { Event::Role::AssistantLeader }

      it "renders" do
        expect(text_with_position(analyzer)).to include(
          [75, 503, "Unterkunft Budget"],
          [195, 503, "Pro Person / Nacht mit Halbpension"],
          [195, 483, "Anreise Klassenleiter"],
          [435, 483, "CHF"],
          [485, 483, "50.0"]
        )
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Anreise ohne validen Ansatz")
      end
    end
  end

  context "as leader" do
    let(:event_role_type) { Event::Role::Leader }

    it "sanitizes filename" do
      expect(subject.filename).to eq "Eckdatenblatt_Kursleiter_edmund_hillary_#{now.strftime("%Y_%m_%d_%H%I")}.pdf"
    end

    context "text" do
      it "renders" do
        find_matches(texts)
      end

      it "renders logo" do
        expect(image_positions).to match_array [expected_logo_position]
      end

      xit "has logo" do
        sections = subject.send(:sections)
        logo_path = sections[0].logo_path
        expect(image_included_in_images?(logo_path)).to be(true)
      end
    end

    context "with multiple leaders" do
      let!(:additional_leaders) do
        (0..3).to_a.map do
          participation = Fabricate(Event::Role::Leader.name.to_sym,
            participation: Fabricate(:event_participation, event: event)).participation
          participation.reload

          participation.person
        end
      end

      it "renders all leaders" do
        leaders_in_pdf = analyzer.show_text[11]
        (additional_leaders + [person]).each do |leader|
          expect(leaders_in_pdf).to include leader.full_name
        end
      end
    end

    context "reserve_accommodation" do
      it "renders sac accommodation if true" do
        event.update!(reserve_accommodation: true)
        text = analyzer.show_text[17]
        expect(text).to eq("Wird reserviert durch SAC")
      end

      it "renders event_specific if false" do
        event.update!(reserve_accommodation: false)
        text = analyzer.show_text[17]
        expect(text).to eq("Wird reserviert durch Kursleitung")
      end
    end
  end

  context "as assistant leader" do
    let(:event_role_type) { Event::Role::AssistantLeader }

    it "sanitizes filename" do
      expect(subject.filename).to eq "Eckdatenblatt_Klassenleiter_edmund_hillary_#{now.strftime("%Y_%m_%d_%H%I")}.pdf"
    end

    context "text" do
      it "renders" do
        find_matches(texts)
      end

      it "renders logo" do
        expect(image_positions).to match_array [expected_logo_position]
      end

      xit "has logo" do
        sections = subject.send(:sections)
        logo_path = sections[0].logo_path
        expect(image_included_in_images?(logo_path)).to be(true)
      end
    end

    context "with multiple leaders" do
      let!(:additional_leaders) do
        (0..3).to_a.map do
          participation = Fabricate(Event::Role::Leader.name.to_sym,
            participation: Fabricate(:event_participation, event: event)).participation
          participation.reload

          participation.person
        end
      end

      it "renders all leaders" do
        leaders_in_pdf = analyzer.show_text[11]
        (additional_leaders + [person]).each do |leader|
          expect(leaders_in_pdf).to include leader.full_name
        end
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
