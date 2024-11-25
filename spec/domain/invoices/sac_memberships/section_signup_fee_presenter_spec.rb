# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMemberships::SectionSignupFeePresenter do
  let(:group) { groups(:bluemlisalp) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.find_by(group_id: group.id).update!(bulletin_postage_abroad: 0)
  end

  date_ranges = [
    OpenStruct.new(range: Date.new(2024, 1, 1)..Date.new(2024, 6, 30), percent: 0),
    OpenStruct.new(range: Date.new(2024, 7, 1)..Date.new(2024, 9, 30), percent: 50),
    OpenStruct.new(range: Date.new(2024, 10, 1)..Date.new(2024, 12, 31), percent: 100)
  ]

  shared_examples "signup_fee_presenter" do |beitragskategorie:, annual_fee:, entry_fee:, abroad_fee:|
    let(:presenter) { described_class.new(group, beitragskategorie.to_s, country: "BE", sac_magazine: true) }

    expected_labels = {family: "Familienmitgliedschaft",
                       adult: "Einzelmitgliedschaft",
                       youth: "Jugendmitgliedschaft"}

    it "has beitragskategorie_label #{expected_labels[beitragskategorie]}" do
      expect(presenter.beitragskategorie_label).to eq expected_labels[beitragskategorie]
    end

    describe "beitragskategorie_amount" do
      it "is identical all year long" do
        travel_to(Date.new(2024, 11)) do
          parts = presenter.beitragskategorie_amount.split(" + ")
          expect(parts.first).to eq "CHF #{format("%.2f", annual_fee)}"
          expect(parts.second).to eq "einmalige Eintrittsgebühr CHF #{format("%.2f", entry_fee)}"
        end
      end

      it "can exclude entry_fee" do
        travel_to(Date.new(2024, 11)) do
          parts = presenter.beitragskategorie_amount(skip_entry_fee: true).split(" + ")
          expect(parts.first).to eq "CHF #{format("%.2f", annual_fee)}"
          expect(parts.second).to be_nil
        end
      end
    end

    context "beitragskategorie=#{beitragskategorie}" do
      it "has expected values set" do
        travel_to(Date.new(2024, 1, 1)) do
          expect(presenter.annual_fee.to_f).to eq(annual_fee)
          expect(presenter.entry_fee.to_f).to eq(entry_fee)
          expect(presenter.total_amount.to_f).to eq(annual_fee + entry_fee + abroad_fee)
        end
      end

      it "has subtracts discount from total" do
        travel_to(Date.new(2024, 8, 10)) do
          expect(presenter.annual_fee.to_f).to eq(annual_fee)
          expect(presenter.entry_fee.to_f).to eq(entry_fee)
        end
      end

      describe "lines" do
        def format_number(number) = format("%.2f", number)

        it "has annual_fee as first line" do
          expect(presenter.lines.first.amount).to eq "CHF #{format_number(annual_fee)}"
          expect(presenter.lines.first.label).to eq "jährlicher Beitrag"
        end

        context "without discount" do
          let(:date) { date_ranges.first.range.to_a.sample }

          before { travel_to(date) }

          it "has 4 lines" do
            expect(presenter.lines).to have(4).items
          end

          it "has entry_fee as second line" do
            expect(presenter.lines.second.amount).to eq "CHF #{format_number(entry_fee)}"
            expect(presenter.lines.second.label).to eq "+ einmalige Eintrittsgebühr"
          end

          it "has abroad_fee as third line" do
            expect(presenter.lines.third.amount).to eq "CHF #{format_number(abroad_fee)}"
            expect(presenter.lines.third.label).to eq "+ Gebühren Ausland"
          end

          it "has total als fourth line" do
            expect(presenter.lines.fourth.amount).to eq "CHF #{format_number(annual_fee + entry_fee + abroad_fee)}"
            expect(presenter.lines.fourth.label).to eq "Total erstmalig"
          end
        end

        context "with discount" do
          let(:date) { date_ranges.second.range.to_a.sample }
          let(:discount_percent) { date_ranges.second.percent }
          let(:discount_amount) { annual_fee * (discount_percent * 0.01) }

          before { travel_to(date) }

          it "has 5 lines" do
            expect(presenter.lines).to have(5).items
          end

          it "has discount as second line" do
            expect(presenter.lines.second.amount).to eq "CHF #{format_number(discount_amount)}"
            expect(presenter.lines.second.label).to eq "- #{discount_percent}% Rabatt auf den jährlichen Beitrag"
          end

          it "has entry_fee as third line" do
            expect(presenter.lines.third.amount).to eq "CHF #{format_number(entry_fee)}"
            expect(presenter.lines.third.label).to eq "+ einmalige Eintrittsgebühr"
          end

          it "has abroad_fee as fourth line" do
            expect(presenter.lines.fourth.amount).to eq "CHF #{format_number(abroad_fee)}"
            expect(presenter.lines.fourth.label).to eq "+ Gebühren Ausland"
          end

          it "has total as fifth line" do
            expect(presenter.lines.fifth.amount).to eq "CHF #{format_number(annual_fee + entry_fee + abroad_fee - discount_amount)}"
            expect(presenter.lines.fifth.label).to eq "Total erstmalig"
          end
        end
      end

      date_ranges.each do |discount|
        context "discount #{discount.percent}%" do
          let(:discount_factor) { discount.percent * 0.01 }
          let(:discount_amount) { annual_fee * discount_factor }

          it "is given from #{discount.range.begin}" do
            travel_to(discount.range.begin) do
              expect(presenter.discount.to_f).to eq discount_amount
              expect(presenter.total_amount.to_f).to eq annual_fee + entry_fee + abroad_fee - discount_amount
            end
          end

          it "is given until #{discount.range.end}" do
            travel_to(discount.range.end) do
              expect(presenter.discount.to_f).to eq discount_amount
              expect(presenter.total_amount.to_f).to eq annual_fee + entry_fee + abroad_fee - discount_amount
            end
          end
        end
      end
    end
  end

  it_behaves_like "signup_fee_presenter", beitragskategorie: :family, annual_fee: 179, entry_fee: 35, abroad_fee: 10
  it_behaves_like "signup_fee_presenter", beitragskategorie: :adult, annual_fee: 127, entry_fee: 20, abroad_fee: 10
  it_behaves_like "signup_fee_presenter", beitragskategorie: :youth, annual_fee: 76, entry_fee: 15, abroad_fee: 10

  context "abroad_fees" do
    before do
      SacSectionMembershipConfig.find_by(group_id: group.id).update!(bulletin_postage_abroad: 100)
    end

    it "does not have abroad fees for a Swiss person" do
      presenter = described_class.new(group, "adult", country: "CH", sac_magazine: true)
      expect(presenter.lines.size).to eq(4)
      expect(presenter.lines.map(&:label)).not_to include("+ Gebühren Ausland")
    end

    it "only has section bulletin postage abroad fees for an abroad person excluded from the magazine" do
      presenter = described_class.new(group, "adult", country: "BE", sac_magazine: false)
      expect(presenter.lines.map(&:label)).to include("+ Gebühren Ausland")
      expect(presenter.lines.map(&:amount)).to include("CHF 100.00")
    end
  end
end
