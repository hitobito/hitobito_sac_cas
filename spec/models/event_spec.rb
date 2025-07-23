# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event do
  describe "::validations" do
    let(:event) { Fabricate.build(:event, dates_attributes: [start_at: Time.zone.today]) }

    it "is valid without training_days" do
      expect(event).to be_valid
    end

    it "is valid if training days are equal to total_duration_days" do
      event.training_days = 1
      expect(event).to be_valid
    end

    it "is invalid if training days exceed total_duration_days" do
      event.training_days = 2
      expect(event).not_to be_valid
      expect(event.errors.full_messages).to eq ["Ausbildungstage muss kleiner oder gleich 1 sein"]
    end
  end
end
