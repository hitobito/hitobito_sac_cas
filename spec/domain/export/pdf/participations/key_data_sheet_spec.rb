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
      [70, 702, "Nachfolgend senden wir dir die wichtigsten Informationen:"],
      [75, 685, "Veranstaltungs-Nr."],
      [195, 685, "10"],
      [75, 664, "Bezeichungs / Titel"],
      [195, 664, "Tourenleiter/in 1 Sommer"],
      [75, 644, "Angebot / Stufe"],
      [195, 644, "Einstiegskurs"],
      [75, 623, "Leitung"],
      [195, 623, "Edmund Hillary"],
      [75, 603, "Tageshonorar"],
      [75, 583, "Durchführungsdatum"],
      [195, 583, "01.03.2023 - "],
      [195, 572, "03.04.2023 - 10.04.2023"],
      [75, 552, "Durchführungsort"],
      [75, 531, "Unterkunft"],
      [195, 531, "Wird reserviert durch SAC"],
      [75, 511, "Unterkunft Budget"],
      [195, 511, "Pro Person / Nacht mit Halbpension"],
      [75, 480, "Unterkunft Kategorie"],
      [195, 480, "ohne Übernachtung"],
      [75, 460, "Durchführungssprache"],
      [195, 460, "Deutsch"],
      [75, 440, "Inhalt / Programm"],
      [195, 440, "Gemäss Stoffprogramm Kurse (falls vorhanden) oder Tourenprogramm"],
      [75, 419, "Teilnehmeranforderungen"],
      [195, 419, "Gemäss Ausschreibung SAC Kurse / Touren 2024"],
      [75, 399, "Detailprogramm Teilnehmer"],
      [75, 388, "Kurse"],
      [195, 399, "Wird von der Geschäftsstelle 8 Wochen vor Beginn per Mail / SAC Cloud bei der Leitung"],
      [195, 388, "eingefordert"],
      [75, 368, "Detailprogramm Teilnehmer"],
      [75, 358, "Touren"],
      [195, 368, "Wird von Geschäftsstelle erstellt und spätestens 6 Wochen vor Beginn in der SAC-"],
      [195, 358, "Cloud hinterlegt"],
      [75, 337, "Anmeldeschluss"],
      [75, 317, "Minimale Teilnehmerzahl"],
      [75, 296, "Maximale Teilnehmerzahl"],
      [75, 276, "Durchführung - ja/nein?"],
      [195, 276, "Entscheid wird gestützt auf Anzahl Anmeldungen beim Anmeldeschluss gemeinsam"],
      [195, 266, "gefällt"],
      [75, 245, "Durchführung – Absage"],
      [195, 245, "Bitte Klassenlehrer und Unterkunft informieren"],
      [75, 225, "Ideale Klassengrösse"],
      [75, 204, "Maximale Klassengrösse"],
      [75, 184, "Klassenlehrer"],
      [195, 184, "Leitung verpflichtet gem. max. Teilnehmerzahl im Voraus die Klassenlehrer - bitte im"],
      [195, 174, "Detailprogramm für Kurse aufführen und für Touren per Mail an Geschäftsstelle senden."],
      [70, 40, "Schweizer Alpen-Club SAC, Monbijoustrasse 61, Postfach, CH-3000 Bern 14, +41 31 370 18 43/44, alpin@sac-cas.ch"]
    ]
  }

  let(:expected_logo_position) {
    {x: 370.28, y: 726.89, width: 397, height: 166, displayed_width: 71460.0, displayed_height: 11620.0}
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
        expect(text_with_position(analyzer)).to include([75, 603, "Tageshonorar"],
          [195, 583, "Tageshonorar Kursleiter"],
          [326, 583, "1"],
          [372, 583, "Tag"],
          [428, 583, "à CHF"],
          [493, 583, "100.0"],
          [195, 562, "Pauschale Kursleiter"],
          [312, 562, "1"],
          [356, 562, "Pauschale"],
          [435, 562, "à CHF"],
          [499, 562, "60.0"])
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Tageshonorar ohne validen Ansatz")
        expect(analyzer.show_text).to_not include("Pauschale ohne validen Ansatz")
      end
    end

    context "as assistant leader" do
      let(:event_role_type) { Event::Role::AssistantLeader }

      it "renders" do
        expect(text_with_position(analyzer)).to include([75, 603, "Tageshonorar"],
          [195, 583, "Tageshonorar Klassenleiter"],
          [338, 583, "1"],
          [382, 583, "Tag"],
          [436, 583, "à CHF"],
          [499, 583, "50.0"],
          [195, 562, "Pauschale Klassenleiter"],
          [322, 562, "1"],
          [364, 562, "Pauschale"],
          [441, 562, "à CHF"],
          [502, 562, "40.0"])
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
      budget_category.course_compensation_rates.create!(rate_leader: 50, rate_assistant_leader: 50, valid_from: event_start_at - 10.days)

      budget_category_without_valid_rate = event.kind.course_compensation_categories.create!(kind: :budget, short_name: "Anreise ohne validen Ansatz", name_leader: "Anreise Kursleiter ohne validen Ansatz", name_assistant_leader: "Anreise Klassenleiter ohne validen Ansatz")
      budget_category_without_valid_rate.course_compensation_rates.create!(rate_leader: 50, rate_assistant_leader: 50, valid_from: event_start_at + 10.days)
    end

    context "as leader" do
      let(:event_role_type) { Event::Role::Leader }

      it "renders" do
        expect(text_with_position(analyzer)).to include([75, 511, "Unterkunft Budget"],
          [195, 511, "Pro Person / Nacht mit Halbpension"],
          [195, 490, "Anreise"],
          [322, 490, "CHF"],
          [439, 490, "50.0"])
      end

      it "does not render categories without valid rate at event start" do
        expect(analyzer.show_text).to_not include("Anreise ohne validen Ansatz")
      end
    end

    context "as assistant leader" do
      let(:event_role_type) { Event::Role::AssistantLeader }

      it "renders" do
        expect(text_with_position(analyzer)).to include([75, 511, "Unterkunft Budget"],
          [195, 511, "Pro Person / Nacht mit Halbpension"],
          [195, 490, "Anreise"],
          [322, 490, "CHF"],
          [439, 490, "50.0"])
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
        expect(text_with_position(analyzer)).to match_array texts
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
        text = analyzer.show_text[18]
        expect(text).to eq("Wird reserviert durch SAC")
      end

      it "renders event_specific if false" do
        event.update!(reserve_accommodation: false)
        text = analyzer.show_text[18]
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
        expect(text_with_position(analyzer)).to match_array texts
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
end
