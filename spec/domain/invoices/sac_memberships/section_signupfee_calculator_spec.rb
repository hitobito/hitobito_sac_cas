# frozen_string_literal: true

require "spec_helper"

describe Invoices::SacMemberships::SectionSignupfeeCalculator do
  let(:sac) { Group.root }
  let(:date) { Date.new(2023, 1, 1) }
  let(:custom_discount) { nil }
  let(:context) { Invoices::SacMemberships::Context.new(date, custom_discount: custom_discount) }
  let(:member) { Invoices::SacMemberships::Member.new(context.people_with_membership_years.find(person.id), context) }
  let(:config) { context.config }
  let(:main_section) { groups(:bluemlisalp) }
  let(:additional_section) { groups(:matterhorn) }
  let(:memberships) { member.active_memberships }
  let(:new_entry) { false }
  let(:group) { groups(:bluemlisalp) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
    Role.update_all(delete_on: date + 3.months)
  end

  context "adult" do
    let(:subject) { described_class.new(group, ActiveSupport::StringInquirer.new("adult")) }

    context "first period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 1, 1)) do
          expect(subject.annual_fee.to_f).to eq(127)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(147)
        end
      end
    end

    context "second period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(subject.annual_fee.to_f).to eq(63.5)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(83.5)
        end
      end
    end

    context "third period" do        
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 11, 1)) do
          expect(subject.annual_fee.to_f).to eq(0)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(20)
        end
      end
    end
  end

  context "family" do
    let(:subject) { described_class.new(group, ActiveSupport::StringInquirer.new("family")) }

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
    let(:subject) { described_class.new(group, ActiveSupport::StringInquirer.new("youth")) }

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

  context "living abroad" do
    let(:subject) { described_class.new(group, ActiveSupport::StringInquirer.new("adult"), sac_magazine: true, selected_country: "DE") }

    context "first period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 1, 1)) do
          expect(subject.annual_fee.to_f).to eq(137)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(157)
        end
      end
    end

    context "second period" do
      it "calculates signup fee" do
        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(subject.annual_fee.to_f).to eq(68.5)
          expect(subject.entry_fee.to_f).to eq(20)
          expect(subject.total_amount.to_f).to eq(88.5)
        end
      end
    end
  end
end
