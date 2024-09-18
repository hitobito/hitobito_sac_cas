# frozen_string_literal: true

require "spec_helper"

describe Invoices::SacMemberships::SectionSignupfeeCalculator do
  let(:group) { groups(:bluemlisalp) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
  end

  context "adult" do
    let(:subject) { described_class.new(group, "adult") }

    context "first period" do
      it "calculates signup fee on first day of period" do
        travel_to(Time.zone.local(2024, 1, 1)) do
          expect(subject.annual_fee.to_f).to eq(127)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(147)
        end
      end

      it "calculates signup fee on last day of period" do
        travel_to(Time.zone.local(2024, 6, 30)) do
          expect(subject.annual_fee.to_f).to eq(127)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(147)
        end
      end
    end

    context "second period" do
      it "calculates signup fee on first day of period" do
        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(subject.annual_fee.to_f).to eq(63.5)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(83.5)
        end
      end

      it "calculates signup fee on last day of period" do
        travel_to(Time.zone.local(2024, 9, 30)) do
          expect(subject.annual_fee.to_f).to eq(63.5)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(83.5)
        end
      end
    end

    context "third period" do
      it "calculates signup fee on first day of period" do
        travel_to(Time.zone.local(2024, 10, 1)) do
          expect(subject.annual_fee.to_f).to eq(0)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(20)
        end
      end

      it "calculates signup fee on last day of period" do
        travel_to(Time.zone.local(2024, 12, 31)) do
          expect(subject.annual_fee.to_f).to eq(0)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(20)
        end
      end
    end

    context "different period dates" do
      it "calculates no discount on 1.7" do
        SacMembershipConfig.last.update!(discount_date_1: "2.7.")

        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(subject.annual_fee.to_f).to eq(127)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(147)
        end
      end

      it "calculates half discount on 1.10" do
        SacMembershipConfig.last.update!(discount_date_2: "2.10.")

        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(subject.annual_fee.to_f).to eq(63.5)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(83.5)
        end
      end

      it "calculates no discount if after third period date" do
        SacMembershipConfig.last.update!(discount_date_3: "1.11.")

        travel_to(Time.zone.local(2024, 12, 1)) do
          expect(subject.annual_fee.to_f).to eq(127)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(147)
        end
      end
    end
  end

  context "family" do
    let(:subject) { described_class.new(group, "family") }

    context "first period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 1, 1)) do
          expect(subject.annual_fee.to_f).to eq(179)
          expect(subject.entry_fee.to_f).to eq(35)
          expect(subject.total_amount.to_f).to eq(214)
        end
      end
    end

    context "second period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(subject.annual_fee.to_f).to eq(89.5)
          expect(subject.entry_fee.to_f).to eq(35)
          expect(subject.total_amount.to_f).to eq(124.5)
        end
      end
    end

    context "third period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 11, 1)) do
          expect(subject.annual_fee.to_f).to eq(0)
          expect(subject.entry_fee.to_f).to eq(35)
          expect(subject.total_amount.to_f).to eq(35)
        end
      end
    end
  end

  context "youth" do
    let(:subject) { described_class.new(group, "youth") }

    context "first period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 1, 1)) do
          expect(subject.annual_fee.to_f).to eq(76)
          expect(subject.entry_fee.to_f).to eq(15)
          expect(subject.total_amount.to_f).to eq(91)
        end
      end
    end

    context "second period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(subject.annual_fee.to_f).to eq(38)
          expect(subject.entry_fee.to_f).to eq(15)
          expect(subject.total_amount.to_f).to eq(53)
        end
      end
    end

    context "third period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 11, 1)) do
          expect(subject.annual_fee.to_f).to eq(0)
          expect(subject.entry_fee.to_f).to eq(15)
          expect(subject.total_amount.to_f).to eq(15)
        end
      end
    end
  end
end
