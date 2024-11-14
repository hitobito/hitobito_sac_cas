#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participations::LeaderSettlement do
  include PdfHelpers

  let(:member) { people(:mitglied) }
  let(:course) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course), start_point_of_time: :day, dates: [
      Event::Date.new(start_at: "01.06.2021", finish_at: "02.06.2021"),
      Event::Date.new(start_at: "07.06.2021", finish_at: "08.06.2021")
    ])
  end
  let!(:rate_day) { Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1), valid_to: Date.new(2022, 5, 1), rate_leader: 20, rate_assistant_leader: 10, course_compensation_category: course_compensation_category(:day)) }
  let!(:rate_flat) { Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 24), valid_to: Date.new(2022, 5, 24), rate_leader: 50, rate_assistant_leader: 25, course_compensation_category: course_compensation_category(:flat)) }
  let!(:rate_budget) { Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 24), valid_to: Date.new(2022, 5, 24), rate_leader: 13, rate_assistant_leader: 13, course_compensation_category: course_compensation_category(:budget)) }
  let!(:participation) { Fabricate(:event_participation, event: course, person: member, actual_days: course.total_event_days) }
  let(:pdf) { described_class.new(participation, "CH93 0076 2011 6238 5295 7").render }
  let(:pdf_content) { PDF::Inspector::Text.analyze(pdf) }

  context "leader" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Role::Leader, self_employed: true)
      course.kind.course_compensation_categories = [course_compensation_category(:day), course_compensation_category(:flat), course_compensation_category(:budget)]
      participation.roles.reload
    end

    it "renders full invoice" do
      invoice_text = [
        [14, 276, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 239, "CH93 0076 2011 6238 5295 7"],
        [14, 228, "Edmund Hillary"],
        [14, 216, "Ophovenerstrasse 79a"],
        [14, 205, "2843 Neu Carlscheid"],
        [14, 173, "Zahlbar durch"],
        [14, 161, "Schweizer Alpen-Club SAC"],
        [14, 150, "Zentralverband, Monbijoustrasse"],
        [14, 138, "61"],
        [14, 127, "3000 Bern 14"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 78, "CHF"],
        [71, 78, "143.00"],
        [105, 39, "Annahmestelle"],
        [190, 276, "Zahlteil"],
        [190, 89, "Währung"],
        [247, 89, "Betrag"],
        [190, 78, "CHF"],
        [247, 78, "143.00"],
        [346, 278, "Konto / Zahlbar an"],
        [346, 266, "CH93 0076 2011 6238 5295 7"],
        [346, 255, "Edmund Hillary"],
        [346, 243, "Ophovenerstrasse 79a"],
        [346, 232, "2843 Neu Carlscheid"],
        [346, 200, "Zahlbar durch"],
        [346, 188, "Schweizer Alpen-Club SAC"],
        [346, 177, "Zentralverband, Monbijoustrasse 61"],
        [346, 165, "3000 Bern 14"]
      ]

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end

    context "total_amount" do
      it "calculates correct total amount when kind has each compensation category once" do
        expect(pdf_content.strings).to include("143.00")
      end

      it "calculates correct total amount when kind has only day and budget category" do
        course.kind.course_compensation_categories = [course_compensation_category(:day), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("93.00")
      end

      it "calculates correct total amount when kind has only day and flat category" do
        course.kind.course_compensation_categories = [course_compensation_category(:day), course_compensation_category(:flat)]
        expect(pdf_content.strings).to include("130.00")
      end

      it "calculates correct total amount when kind has only budget and flat category" do
        course.kind.course_compensation_categories = [course_compensation_category(:budget), course_compensation_category(:flat)]
        expect(pdf_content.strings).to include("63.00")
      end

      it "calculates correct total_amount when having multiple day categories" do
        second_day_category = CourseCompensationCategory.create!(short_name: "HO-KAT-II", kind: "day")
        Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1), valid_to: Date.new(2022, 5, 1), rate_leader: 20, rate_assistant_leader: 10, course_compensation_category: second_day_category)
        course.kind.course_compensation_categories = [course_compensation_category(:day), second_day_category, course_compensation_category(:flat), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("223.00")
      end

      it "calculates correct total_amount when having multiple budget categories" do
        second_budget_category = CourseCompensationCategory.create!(short_name: "UB-HUETTE-II", kind: "budget")
        Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1), valid_to: Date.new(2022, 5, 1), rate_leader: 30, rate_assistant_leader: 20, course_compensation_category: second_budget_category)
        course.kind.course_compensation_categories = [course_compensation_category(:day), second_budget_category, course_compensation_category(:flat), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("173.00")
      end

      it "calculates correct total_amount when having multiple flat categories" do
        second_flat_category = CourseCompensationCategory.create!(short_name: "KP-REISE/MATERIAL-II", kind: "flat")
        Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1), valid_to: Date.new(2022, 5, 1), rate_leader: 50, rate_assistant_leader: 40, course_compensation_category: second_flat_category)
        course.kind.course_compensation_categories = [course_compensation_category(:day), second_flat_category, course_compensation_category(:flat), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("193.00")
      end
    end
  end

  context "assistant leader" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Role::AssistantLeader, self_employed: true)
      course.kind.course_compensation_categories = [course_compensation_category(:day), course_compensation_category(:flat), course_compensation_category(:budget)]
      participation.roles.reload
    end

    it "renders full invoice" do
      invoice_text = [
        [14, 276, "Empfangsschein"],
        [14, 251, "Konto / Zahlbar an"],
        [14, 239, "CH93 0076 2011 6238 5295 7"],
        [14, 228, "Edmund Hillary"],
        [14, 216, "Ophovenerstrasse 79a"],
        [14, 205, "2843 Neu Carlscheid"],
        [14, 173, "Zahlbar durch"],
        [14, 161, "Schweizer Alpen-Club SAC"],
        [14, 150, "Zentralverband, Monbijoustrasse"],
        [14, 138, "61"],
        [14, 127, "3000 Bern 14"],
        [14, 89, "Währung"],
        [71, 89, "Betrag"],
        [14, 78, "CHF"],
        [71, 78, "78.00"],
        [105, 39, "Annahmestelle"],
        [190, 276, "Zahlteil"],
        [190, 89, "Währung"],
        [247, 89, "Betrag"],
        [190, 78, "CHF"],
        [247, 78, "78.00"],
        [346, 278, "Konto / Zahlbar an"],
        [346, 266, "CH93 0076 2011 6238 5295 7"],
        [346, 255, "Edmund Hillary"],
        [346, 243, "Ophovenerstrasse 79a"],
        [346, 232, "2843 Neu Carlscheid"],
        [346, 200, "Zahlbar durch"],
        [346, 188, "Schweizer Alpen-Club SAC"],
        [346, 177, "Zentralverband, Monbijoustrasse 61"],
        [346, 165, "3000 Bern 14"]
      ]

      text_with_position.each_with_index do |l, i|
        expect(l).to eq(invoice_text[i])
      end
    end

    context "total_amount" do
      it "calculates correct total amount when kind has each compensation category once" do
        expect(pdf_content.strings).to include("78.00")
      end

      it "calculates correct total amount when kind has only day and budget category" do
        course.kind.course_compensation_categories = [course_compensation_category(:day), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("53.00")
      end

      it "calculates correct total amount when kind has only day and flat category" do
        course.kind.course_compensation_categories = [course_compensation_category(:day), course_compensation_category(:flat)]
        expect(pdf_content.strings).to include("65.00")
      end

      it "calculates correct total amount when kind has only budget and flat category" do
        course.kind.course_compensation_categories = [course_compensation_category(:budget), course_compensation_category(:flat)]
        expect(pdf_content.strings).to include("38.00")
      end

      it "calculates correct total_amount when having multiple day categories" do
        second_day_category = CourseCompensationCategory.create!(short_name: "HO-KAT-II", kind: "day")
        Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1), valid_to: Date.new(2022, 5, 1), rate_leader: 20, rate_assistant_leader: 10, course_compensation_category: second_day_category)
        course.kind.course_compensation_categories = [course_compensation_category(:day), second_day_category, course_compensation_category(:flat), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("118.00")
      end

      it "calculates correct total_amount when having multiple budget categories" do
        second_budget_category = CourseCompensationCategory.create!(short_name: "UB-HUETTE-II", kind: "budget")
        Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1), valid_to: Date.new(2022, 5, 1), rate_leader: 30, rate_assistant_leader: 20, course_compensation_category: second_budget_category)
        course.kind.course_compensation_categories = [course_compensation_category(:day), second_budget_category, course_compensation_category(:flat), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("98.00")
      end

      it "calculates correct total_amount when having multiple flat categories" do
        second_flat_category = CourseCompensationCategory.create!(short_name: "KP-REISE/MATERIAL-II", kind: "flat")
        Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1), valid_to: Date.new(2022, 5, 1), rate_leader: 50, rate_assistant_leader: 40, course_compensation_category: second_flat_category)
        course.kind.course_compensation_categories = [course_compensation_category(:day), second_flat_category, course_compensation_category(:flat), course_compensation_category(:budget)]
        expect(pdf_content.strings).to include("118.00")
      end
    end
  end
end
