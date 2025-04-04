#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participations::LeaderSettlement do
  include PdfHelpers

  def create_course_compensation(kind:, rate_leader: 0, rate_assistant_leader: 0, rate_leader_aspirant: 0, rate_assistant_leader_aspirant: 0, rate_leadership1: 0, rate_leadership2: 0, rate_leadership3: 0, rate_leadership4: 0)
    category = CourseCompensationCategory.create!(short_name: "DUMMY", kind: kind, name_leader: "DUMMY", name_assistant_leader: "DUMMY")
    Fabricate.create(
      :course_compensation_rate,
      valid_from: Date.new(2021, 5, 1),
      valid_to: Date.new(2022, 5, 1),
      rate_leader: rate_leader,
      rate_assistant_leader: rate_assistant_leader,
      rate_leader_aspirant: rate_leader_aspirant,
      rate_assistant_leader_aspirant: rate_assistant_leader_aspirant,
      rate_leadership1: rate_leadership1,
      rate_leadership2: rate_leadership2,
      rate_leadership3: rate_leadership3,
      rate_leadership4: rate_leadership4,
      course_compensation_category: category
    )
    category
  end

  let(:member) { people(:mitglied) }
  let(:course) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course), start_point_of_time: :day, number: "2021-00202", dates: [
      Event::Date.new(start_at: "01.06.2021", finish_at: "02.06.2021"),
      Event::Date.new(start_at: "07.06.2021", finish_at: "08.06.2021")
    ])
  end
  let!(:rate_day) {
    Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 1),
      valid_to: Date.new(2022, 5, 1),
      rate_leader: 20,
      rate_assistant_leader: 10,
      rate_leader_aspirant: 7,
      rate_assistant_leader_aspirant: 5,
      rate_leadership1: 8,
      rate_leadership2: 18,
      rate_leadership3: 87,
      rate_leadership4: 15,
      course_compensation_category: course_compensation_categories(:day))
  }
  let!(:rate_flat) {
    Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 24),
      valid_to: Date.new(2022, 5, 24),
      rate_leader: 50,
      rate_assistant_leader: 25,
      rate_leader_aspirant: 12,
      rate_assistant_leader_aspirant: 32,
      rate_leadership1: 76,
      rate_leadership2: 12,
      rate_leadership3: 32,
      rate_leadership4: 98,
      course_compensation_category: course_compensation_categories(:flat))
  }
  let!(:rate_budget) {
    Fabricate.create(:course_compensation_rate, valid_from: Date.new(2021, 5, 24),
      valid_to: Date.new(2022, 5, 24),
      rate_leader: 13,
      rate_assistant_leader: 13,
      rate_leader_aspirant: 1,
      rate_assistant_leader_aspirant: 4,
      rate_leadership1: 5,
      rate_leadership2: 8,
      rate_leadership3: 17,
      rate_leadership4: 71,
      course_compensation_category: course_compensation_categories(:budget))
  }
  let!(:participation) { Fabricate(:event_participation, event: course, person: member, actual_days: course.total_event_days) }
  let(:pdf) { described_class.new(participation, "CH93 0076 2011 6238 5295 7").render }
  let(:pdf_content) { PDF::Inspector::Text.analyze(pdf) }
  let(:today) { Time.zone.today }

  before do
    course.kind.course_compensation_categories = [course_compensation_categories(:day), course_compensation_categories(:flat), course_compensation_categories(:budget)]
  end

  shared_examples "renders full invoice" do |total_amount:|
    it "does render full invoice" do
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
        [71, 78, total_amount],
        [105, 39, "Annahmestelle"],
        [190, 276, "Zahlteil"],
        [190, 89, "Währung"],
        [247, 89, "Betrag"],
        [190, 78, "CHF"],
        [247, 78, total_amount],
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

      invoice_text.each_with_index do |l, i|
        expect(text_with_position[i + 33]).to eq(l)
      end
    end
  end

  shared_examples "total amount" do |rate_name:|
    it "calculates correct total amount when kind has each compensation category once" do
      total_amount = (rate_day.send(rate_name) * 4) + rate_flat.send(rate_name) + rate_budget.send(rate_name)
      expect(pdf_content.strings).to include("#{total_amount.to_f}0")
    end

    it "calculates correct total amount when kind has only day and budget category" do
      course.kind.course_compensation_categories = [course_compensation_categories(:day), course_compensation_categories(:budget)]
      total_amount = (rate_day.send(rate_name) * 4) + rate_budget.send(rate_name)
      expect(pdf_content.strings).to include("#{total_amount.to_f}0")
    end

    it "calculates correct total amount when kind has only day and flat category" do
      course.kind.course_compensation_categories = [course_compensation_categories(:day), course_compensation_categories(:flat)]
      total_amount = (rate_day.send(rate_name) * 4) + rate_flat.send(rate_name)
      expect(pdf_content.strings).to include("#{total_amount.to_f}0")
    end

    it "calculates correct total amount when kind has only budget and flat category" do
      course.kind.course_compensation_categories = [course_compensation_categories(:budget), course_compensation_categories(:flat)]
      total_amount = rate_flat.send(rate_name) + rate_budget.send(rate_name)
      expect(pdf_content.strings).to include("#{total_amount.to_f}0")
    end

    it "calculates correct total_amount when having multiple day categories" do
      second_day_category = create_course_compensation(:kind => "day", rate_name.to_sym => 20)
      course.kind.course_compensation_categories = [course_compensation_categories(:day), second_day_category, course_compensation_categories(:budget), course_compensation_categories(:flat)]
      total_amount = (rate_day.send(rate_name) * 4) + (second_day_category.course_compensation_rates.first.send(rate_name) * 4) + rate_flat.send(rate_name) + rate_budget.send(rate_name)
      expect(pdf_content.strings).to include("#{total_amount.to_f}0")
    end

    it "calculates correct total_amount when having multiple budget categories" do
      second_budget_category = create_course_compensation(:kind => "budget", rate_name.to_sym => 30)
      course.kind.course_compensation_categories = [course_compensation_categories(:day), second_budget_category, course_compensation_categories(:budget), course_compensation_categories(:flat)]
      total_amount = (rate_day.send(rate_name) * 4) + rate_flat.send(rate_name) + rate_budget.send(rate_name) + second_budget_category.course_compensation_rates.first.send(rate_name)
      expect(pdf_content.strings).to include("#{total_amount.to_f}0")
    end

    it "calculates correct total_amount when having multiple flat categories" do
      second_flat_category = create_course_compensation(:kind => "flat", rate_name.to_sym => 50)
      course.kind.course_compensation_categories = [course_compensation_categories(:day), second_flat_category, course_compensation_categories(:budget), course_compensation_categories(:flat)]
      total_amount = (rate_day.send(rate_name) * 4) + rate_flat.send(rate_name) + rate_budget.send(rate_name) + second_flat_category.course_compensation_rates.first.send(rate_name)
      expect(pdf_content.strings).to include("#{total_amount.to_f}0")
    end
  end

  context "leader" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::Leader, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "143.00"

    it_behaves_like "total amount",
      rate_name: :rate_leader
  end

  context "assistant leader" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::AssistantLeader, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "78.00"

    it_behaves_like "total amount",
      rate_name: :rate_assistant_leader
  end

  context "leader aspirant" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::LeaderAspirant, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "41.00"

    it_behaves_like "total amount",
      rate_name: :rate_leader_aspirant
  end

  context "assistant leader aspirant" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::AssistantLeaderAspirant, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "56.00"

    it_behaves_like "total amount",
      rate_name: :rate_assistant_leader_aspirant
  end

  context "leadership 1" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::Leadership1, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "113.00"

    it_behaves_like "total amount",
      rate_name: :rate_leadership1
  end

  context "leadership 2" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::Leadership2, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "92.00"

    it_behaves_like "total amount",
      rate_name: :rate_leadership2
  end

  context "leadership 3" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::Leadership3, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "397.00"

    it_behaves_like "total amount",
      rate_name: :rate_leadership3
  end

  context "leadership 4" do
    before do
      Fabricate.create(:event_role, participation: participation, type: Event::Course::Role::Leadership4, self_employed: true)
      participation.roles.reload
    end

    it_behaves_like "renders full invoice",
      total_amount: "229.00"

    it_behaves_like "total amount",
      rate_name: :rate_leadership4
  end
end
