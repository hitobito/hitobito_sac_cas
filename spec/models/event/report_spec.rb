# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Report do
  let(:report) { event_reports(:section_tour_report) }

  describe "#status" do
    it "is draft when submitted_at is nil" do
      expect(report.status).to eq :draft
    end

    it "is review when submitted_at is set" do
      report.submitted_at = 1.day.ago

      expect(report.status).to eq :review
    end

    it "is approved when approved_at is set" do
      report.approved_at = 1.day.ago

      expect(report.status).to eq :approved
    end

    it "is closed when paid_at is set" do
      report.paid_at = 1.day.ago

      expect(report.status).to eq :closed
    end
  end

  describe "#status_label" do
    it "returns label for the current status" do
      expect(report.status_label).to eq "Entwurf"
    end
  end
end
