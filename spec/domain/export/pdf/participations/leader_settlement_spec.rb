#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participations::LeaderSettlement do
  include PdfHelpers

  let(:member) { people(:mitglied) }
  let(:course) do
    Fabricate(:sac_course,
      kind: event_kinds(:ski_course), start_point_of_time: :day, number: "2021-00202", dates: [
        Event::Date.new(start_at: "01.06.2021", finish_at: "02.06.2021"),
        Event::Date.new(start_at: "07.06.2021", finish_at: "08.06.2021")
      ])
  end
  let!(:rate_day) {
    Fabricate.create(:course_compensation_rate,
      valid_from: Date.new(2021, 5, 1),
      valid_to: Date.new(2022, 5, 1),
      rate_leader: 20,
      rate_assistant_leader: 10,
      rate_leader_aspirant: 7,
      rate_assistant_leader_aspirant: 5,
      course_compensation_category: course_compensation_categories(:day))
  }
  let!(:rate_flat) {
    Fabricate.create(:course_compensation_rate,
      valid_from: Date.new(2021, 5, 24),
      valid_to: Date.new(2022, 5, 24),
      rate_leader: 50,
      rate_assistant_leader: 25,
      rate_leader_aspirant: 12,
      rate_assistant_leader_aspirant: 32,
      course_compensation_category: course_compensation_categories(:flat))
  }
  let!(:rate_budget) {
    Fabricate.create(:course_compensation_rate,
      valid_from: Date.new(2021, 5, 24),
      valid_to: Date.new(2022, 5, 24),
      rate_leader: 13,
      rate_assistant_leader: 13,
      rate_leader_aspirant: 1,
      rate_assistant_leader_aspirant: 4,
      course_compensation_category: course_compensation_categories(:budget))
  }
  let!(:participation) do
    Fabricate(:event_participation,
      event: course,
      participant: member,
      actual_days: course.total_event_days)
  end
  let(:pdf) { described_class.new(participation, "CH93 0076 2011 6238 5295 7").render }
  let(:pdf_content) { PDF::Inspector::Text.analyze(pdf) }
  let(:today) { Time.zone.today }

  before do
    course.kind.course_compensation_categories = [
      course_compensation_categories(:day),
      course_compensation_categories(:flat),
      course_compensation_categories(:budget)
    ]
  end

  # rubocop:todo Metrics/MethodLength
  def create_course_compensation(kind:, rate_leader: 0, rate_assistant_leader: 0,
    rate_leader_aspirant: 0, rate_assistant_leader_aspirant: 0)
    category = CourseCompensationCategory.create!(
      short_name: "DUMMY",
      kind: kind,
      name_leader: "DUMMY",
      name_assistant_leader: "DUMMY"
    )
    Fabricate.create(
      :course_compensation_rate,
      valid_from: Date.new(2021, 5, 1),
      valid_to: Date.new(2022, 5, 1),
      rate_leader: rate_leader,
      rate_assistant_leader: rate_assistant_leader,
      rate_leader_aspirant: rate_leader_aspirant,
      rate_assistant_leader_aspirant: rate_assistant_leader_aspirant,
      course_compensation_category: category
    )
    category
  end
  # rubocop:enable Metrics/MethodLength

  context "leader" do
    before do
      Fabricate.create(:event_role,
        participation: participation,
        type: Event::Course::Role::Leader,
        self_employed: true)
      participation.roles.reload
    end

    it "renders full invoice" do
      invoice_text = [
        [57, 806, "Edmund Hillary"],
        [57, 793, "Ophovenerstrasse 79a"],
        [57, 781, "2843 Neu Carlscheid"],
        [57, 685, "Rechnungsnummer:"],
        [163, 685, "600001-#{today.strftime("%Y-%m-%d")}"],
        [57, 672, "Rechnungsdatum:"],
        [163, 672, today.strftime("%d.%m.%Y")],
        [57, 659, "Rechnungssteller:"],
        [163, 659, "Edmund Hillary"],
        [347, 686, "Schweizer Alpen-Club SAC"],
        [347, 674, "Zentralverband, Monbijoustrasse 61"],
        [347, 662, "3000 Bern 14"],
        [57, 554, "2021-00202 — Eventus"],
        [57, 521, "Rechnungsartikel"],
        [412, 521, "Anzahl"],
        [469, 521, "Preis"],
        [512, 521, "Betrag"],
        [57, 506, "Tageshonorar - Kursleitung"],
        [433, 506, "4"],
        [467, 506, "20.00"],
        [517, 506, "80.00"],
        [57, 491, "Kurspauschale - Kursleitung"],
        [433, 491, "1"],
        [467, 491, "50.00"],
        [517, 491, "50.00"],
        [57, 476, "SAC Hütte"],
        [433, 476, "1"],
        [467, 476, "13.00"],
        [517, 476, "13.00"],
        [396, 461, "Zwischenbetrag"],
        [497, 461, "143.00 CHF"],
        [396, 443, "Gesamtbetrag"],
        [497, 443, "143.00 CHF"],
        [14, 275, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 242, "CH93 0076 2011 6238 5295 7"],
        [14, 233, "Edmund Hillary"],
        [14, 225, "Ophovenerstrasse 79a"],
        [14, 216, "2843 Neu Carlscheid"],
        [14, 197, "Zahlbar durch"],
        [14, 189, "Schweizer Alpen-Club SAC"],
        [14, 180, "Zentralverband, Monbijoustrasse 61"],
        [14, 171, "3000 Bern 14"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 77, "CHF"],
        [71, 77, "143.00"],
        [105, 39, "Annahmestelle"],
        [190, 275, "Zahlteil"],
        [190, 88, "Währung"],
        [247, 88, "Betrag"],
        [190, 76, "CHF"],
        [247, 76, "143.00"],
        [346, 276, "Konto / Zahlbar an"],
        [346, 265, "CH93 0076 2011 6238 5295 7"],
        [346, 254, "Edmund Hillary"],
        [346, 244, "Ophovenerstrasse 79a"],
        [346, 233, "2843 Neu Carlscheid"],
        [346, 212, "Zahlbar durch"],
        [346, 201, "Schweizer Alpen-Club SAC"],
        [346, 190, "Zentralverband, Monbijoustrasse 61"],
        [346, 179, "3000 Bern 14"]
      ]

      invoice_text.each_with_index do |l, i|
        expect(text_with_position[i]).to eq(l)
      end
    end

    def find_text_at(x, y) = text_with_position.find { _1.first == x && _1.second == y }&.last

    it "renders half days" do
      participation.update(actual_days: 4.5)
      expect(find_text_at(426, 506)).to eq "4.5"
      expect(find_text_at(467, 506)).to eq "20.00"
      expect(find_text_at(517, 506)).to eq "90.00"
    end

    it "excludes compensation rates for non-leader-settlement categories" do
      course_compensation_categories(:budget).update!(leader_settlement: false)

      strings = pdf_content.strings
      expect(strings).not_to include("SAC Hütte")
      expect(strings).to include("130.00")
    end

    context "total_amount" do
      it "calculates correct total amount when kind has each compensation category once" do
        expect(pdf_content.strings).to include("143.00")
      end

      it "calculates correct total amount when kind has only day and budget category" do
        course.kind.course_compensation_categories = [
          course_compensation_categories(:day),
          course_compensation_categories(:budget)
        ]

        expect(pdf_content.strings).to include("93.00")
      end

      it "calculates correct total amount when kind has only day and flat category" do
        course.kind.course_compensation_categories = [
          course_compensation_categories(:day),
          course_compensation_categories(:flat)
        ]

        expect(pdf_content.strings).to include("130.00")
      end

      it "calculates correct total amount when kind has only budget and flat category" do
        course.kind.course_compensation_categories = [
          course_compensation_categories(:budget),
          course_compensation_categories(:flat)
        ]

        expect(pdf_content.strings).to include("63.00")
      end

      it "calculates correct total_amount when having multiple day categories" do
        second_day_category = create_course_compensation(
          kind: "day",
          rate_leader: 20,
          rate_assistant_leader: 10
        )
        course.kind.course_compensation_categories = [
          course_compensation_categories(:day),
          second_day_category,
          course_compensation_categories(:budget),
          course_compensation_categories(:flat)
        ]

        expect(pdf_content.strings).to include("223.00")
      end

      it "calculates correct total_amount when having multiple budget categories" do
        second_budget_category = create_course_compensation(
          kind: "budget",
          rate_leader: 30,
          rate_assistant_leader: 20
        )
        course.kind.course_compensation_categories = [
          course_compensation_categories(:day),
          second_budget_category,
          course_compensation_categories(:budget),
          course_compensation_categories(:flat)
        ]

        expect(pdf_content.strings).to include("173.00")
      end

      it "calculates correct total_amount when having multiple flat categories" do
        second_flat_category = create_course_compensation(
          kind: "flat",
          rate_leader: 50,
          rate_assistant_leader: 40
        )
        course.kind.course_compensation_categories = [
          course_compensation_categories(:day),
          second_flat_category,
          course_compensation_categories(:budget),
          course_compensation_categories(:flat)
        ]

        expect(pdf_content.strings).to include("193.00")
      end

      it "calculates correct total_amount when having no categories" do
        course.kind.course_compensation_categories = []

        expect(pdf_content.strings).to include("0.00 CHF")
      end

      it "calculates total_amount for highest role if multiple exist" do
        Fabricate.create(:event_role,
          participation: participation,
          type: Event::Course::Role::AssistantLeaderAspirant,
          self_employed: true)

        expect(pdf_content.strings).to include("143.00")
      end
    end
  end

  context "assistant leader" do
    before do
      Fabricate.create(:event_role,
        participation: participation,
        type: Event::Course::Role::AssistantLeader,
        self_employed: true)
      participation.roles.reload
    end

    it "calculates correct total amount when kind has each compensation category once" do
      expect(pdf_content.strings).to include("78.00")
      expect(pdf_content.strings).to include("Tageshonorar - Klassenleitung")
    end
  end

  context "leader aspirant" do
    before do
      Fabricate.create(:event_role,
        participation: participation,
        type: Event::Course::Role::LeaderAspirant,
        self_employed: true)
      participation.roles.reload
    end

    it "calculates correct total amount when kind has each compensation category once" do
      expect(pdf_content.strings).to include("41.00")
      expect(pdf_content.strings).to include("HO-KAT-I")
    end
  end

  context "assistant leader aspirant" do
    before do
      Fabricate.create(:event_role,
        participation: participation,
        type: Event::Course::Role::AssistantLeaderAspirant,
        self_employed: true)
      participation.roles.reload
      course_compensation_categories(:day).update!(
        name_assistant_leader_aspirant: "Tageshonorar - Klassenleitung Aspirant"
      )
    end

    it "calculates correct total amount when kind has each compensation category once" do
      expect(pdf_content.strings).to include("56.00")
      expect(pdf_content.strings).to include("Tageshonorar - Klassenleitung Aspirant")
    end
  end
end
