# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::CourseAnnulationCost do
  let(:member) { people(:mitglied) }
  let(:course) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course), dates: [
      Event::Date.new(start_at: "01.01.2024", finish_at: "31.01.2024"),
      Event::Date.new(start_at: "01.03.2024", finish_at: "31.03.2024")
    ])
  end
  let(:participation) { Fabricate(:event_participation, event: course, participant: member, price: 200, price_category: :price_regular) }

  subject { described_class.new(participation) }

  context "#amount_cancelled" do
    it "returns full price when cancelled 9 days or less before course start" do
      allow(participation).to receive(:canceled_at).and_return(Date.new(2023, 12, 23))
      expect(subject.amount_cancelled).to eq(200)
    end

    it "returns 75% of price when cancelled 10-19 days before course start" do
      allow(participation).to receive(:canceled_at).and_return(Date.new(2023, 12, 15))
      expect(subject.amount_cancelled).to eq(150)
    end

    it "returns 50% of price when cancelled 20-30 days before course start" do
      allow(participation).to receive(:canceled_at).and_return(Date.new(2023, 12, 5))
      expect(subject.amount_cancelled).to eq(100)
    end

    it "returns processing fee when cancelled more than 30 days before start" do
      allow(participation).to receive(:canceled_at).and_return(Date.new(2023, 11, 30))
      expect(subject.amount_cancelled).to eq(80.0)
    end
  end

  context "#position_description_and_amount_cancelled" do
    it "returns description and correct amount" do
      allow(participation).to receive(:canceled_at).and_return(Date.new(2023, 12, 15))
      expect(subject.position_description_and_amount_cancelled).to eq(["75% Annullationskosten", 150])
    end
  end

  context "#position_description_and_amount_absent" do
    it "returns full cancellation description and price" do
      expect(subject.position_description_and_amount_absent).to eq(["100% Annullationskosten", 200])
    end
  end
end
