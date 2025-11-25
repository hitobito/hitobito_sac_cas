#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe People::Export::PeriodForm do
  let(:sektion) { groups(:bluemlisalp) }
  let(:today) { Time.zone.today }

  subject(:form) { described_class.new }

  describe "defaults" do
    it "defaults from to beginning_of_year" do
      expect(form.from).to eq today.beginning_of_year
    end

    it "defaults to to end_of_year" do
      expect(form.to).to eq today.end_of_year
    end
  end

  describe "validations" do
    it "is valid without params set" do
      expect(form).to be_valid
    end

    it "is valid if until is exactly one year" do
      form.to = form.from + 1.year - 1.day
      expect(form).to be_valid
    end

    it "is invalid if until more than one year after from" do
      travel_to(Time.zone.local(2025, 11, 3)) do
        form.to = form.from + 1.year + 1.day
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Der Zeitraum darf maximimal 12 Monate betragen."]
      end
    end

    it "is invalid if until is before from" do
      travel_to(Time.zone.local(2025, 11, 3)) do
        form.from = 20.days.from_now
        form.to = 20.days.ago
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Bis muss 23.11.2025 oder danach sein"]
      end
    end
  end
end
