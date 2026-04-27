# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe HoursDuration do
  describe "parse" do
    it "does not allow negative integers" do
      expect(HoursDuration.parse(-1).valid?).to eq(false)

      expect(HoursDuration.parse("-1").valid?).to eq(false)
    end

    it "sets integer hours" do
      duration = HoursDuration.parse("12")

      expect(duration.total_minutes).to eq(720) # 12 * 60

      expect(duration.to_s).to eq("12:00")

      duration = HoursDuration.parse("2")

      expect(duration.total_minutes).to eq(120) # 2 * 60

      expect(duration.to_s).to eq("2:00")
    end

    it "sets military time (e.g 1430)" do
      duration = HoursDuration.parse("1430")

      expect(duration.total_minutes).to eq(870) # 14 * 60 + 30

      expect(duration.to_s).to eq("14:30")

      duration = HoursDuration.parse("140")

      expect(duration.total_minutes).to eq(100) # 1 * 60 + 40

      expect(duration.to_s).to eq("1:40")
    end

    it "sets decimal hours" do
      duration = HoursDuration.parse("6.5")

      expect(duration.total_minutes).to eq(390) # 6 * 60 + 30

      expect(duration.to_s).to eq("6:30")

      duration = HoursDuration.parse("2")

      expect(duration.total_minutes).to eq(120) # 2 * 60

      expect(duration.to_s).to eq("2:00")
    end

    it "sets hh:mm format" do
      duration = HoursDuration.parse("12:20")

      expect(duration.total_minutes).to eq(740) # 12 * 60 + 20

      expect(duration.to_s).to eq("12:20")

      duration = HoursDuration.parse("3:15")

      expect(duration.total_minutes).to eq(195) # 3 * 60 + 15

      expect(duration.to_s).to eq("3:15")

      duration = HoursDuration.parse("4:5")

      expect(duration.total_minutes).to eq(245) # 4 * 60 + 5

      expect(duration.to_s).to eq("4:05")
    end
  end
end
