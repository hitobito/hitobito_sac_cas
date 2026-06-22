# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::CostReceipt do
  let(:receipt) { event_cost_receipts(:tankstelle) }

  describe "validations" do
    it "is valid" do
      expect(receipt).to be_valid
    end

    it "requires description" do
      receipt.description = nil

      expect(receipt).not_to be_valid
    end
  end
end
