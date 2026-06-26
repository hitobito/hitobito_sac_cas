# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Tour::ReportForm do
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let(:form) { described_class.new(report) }

  it "assigns attributes from report" do
    expect(form.review).to eq(report.review)
    expect(form.remarks).to eq(report.remarks)
  end

  describe "#save" do
    it "persists changed attributes to the report" do
      form.review = "Updated review"
      form.remarks = "Some remarks"

      expect { form.save }
        .to change { report.reload.review }.to("Updated review")
        .and change { report.reload.remarks }.to("Some remarks")
    end
  end

  describe "#tour_completed?" do
    it "returns false when tour is in progress states" do
      expect(form.tour_completed?).to be_falsey
    end

    it "returns true when tour is ready" do
      event.update_column(:state, :ready)

      expect(form.tour_completed?).to be_truthy
    end

    it "returns true when tour is closed" do
      event.update_column(:state, :closed)

      expect(form.tour_completed?).to be_truthy
    end
  end
end
