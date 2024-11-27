# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Courses::LeaderSettlementForm do
  describe "validations" do
    let(:course) do
      course = Fabricate.build(:sac_course, start_point_of_time: :day)
      course.dates.build(start_at: Time.zone.local(2012, 5, 11))
      course
    end

    subject(:leader_settlement_invoice) { described_class.new(iban: "CH93 0076 2011 6238 5295 7", actual_days: 1, course: course) }

    it "is valid with correct attributes" do
      expect(leader_settlement_invoice).to be_valid
    end

    it "is invalid without an iban" do
      leader_settlement_invoice.iban = nil
      expect(leader_settlement_invoice).not_to be_valid
      expect(leader_settlement_invoice.errors.full_messages).to eq ["IBAN muss ausgefüllt werden"]
    end

    it "is invalid with an incorrect IBAN format" do
      leader_settlement_invoice.iban = "INVALID_IBAN"
      expect(leader_settlement_invoice).not_to be_valid
      expect(leader_settlement_invoice.errors.full_messages).to eq ["IBAN ist nicht gültig"]
    end

    it "is invalid without actual_days" do
      leader_settlement_invoice.actual_days = nil
      expect(leader_settlement_invoice).not_to be_valid
      expect(leader_settlement_invoice.errors.full_messages).to eq ["Effektive Tage muss ausgefüllt werden"]
    end

    it "is invalid when actual_days is negative" do
      leader_settlement_invoice.actual_days = -1
      expect(leader_settlement_invoice).not_to be_valid
      expect(leader_settlement_invoice.errors.full_messages).to eq ["Effektive Tage muss größer oder gleich 0 sein"]
    end

    it "is invalid when actual_days exceeds course total days" do
      leader_settlement_invoice.actual_days = 2
      expect(leader_settlement_invoice).not_to be_valid
      expect(leader_settlement_invoice.errors.full_messages).to eq ["Effektive Tage darf die totalen Tage des Kurses nicht überschreiten"]
    end
  end
end
