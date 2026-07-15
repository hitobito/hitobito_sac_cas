# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Cost do
  let(:event_cost) { event_costs(:transport) }

  describe "validations" do
    it "is valid" do
      expect(event_cost).to be_valid
    end

    it "requires description" do
      event_cost.description = nil

      expect(event_cost).not_to be_valid
    end

    it "requires count" do
      event_cost.description = nil

      expect(event_cost).not_to be_valid
    end

    it "requires amount" do
      event_cost.description = nil

      expect(event_cost).not_to be_valid
    end
  end

  describe "#total" do
    it "calculates total of amount and count" do
      expect(event_cost.total).to eq 300
    end

    it "is zero when amount is nil" do
      event_cost.amount = nil

      expect(event_cost.total).to be_zero
    end

    it "is zero when count is nil" do
      event_cost.count = nil

      expect(event_cost.total).to be_zero
    end
  end
end
