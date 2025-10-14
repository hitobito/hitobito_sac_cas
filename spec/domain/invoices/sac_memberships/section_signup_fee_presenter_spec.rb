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
  end

  discount = Data.define(:range, :percent) do
    def day = range.to_a.sample

    def factor = percent * 0.01

    def calc(amount) = amount * factor

    def apply(amount) = amount - calc(amount)
  end

  discount_ranges = [
    discount.new(range: Date.new(2024, 7, 1)..Date.new(2024, 9, 30), percent: 50),
    discount.new(range: Date.new(2024, 10, 1)..Date.new(2024, 12, 31), percent: 100)
  ]

  # rubocop:todo Layout/LineLength
  shared_examples "signup_fee_presenter" do |beitragskategorie:, annual_fee:, entry_fee:, section_fee:, abroad_fees:|
    # rubocop:enable Layout/LineLength
    let(:person) { Person.new }
    let(:presenter) { described_class.new(group, beitragskategorie.to_s, person) }

    expected_labels = {family: "Familienmitgliedschaft",
                       adult: "Einzelmitgliedschaft",
                       youth: "Jugendmitgliedschaft"}

    def format_number(number) = format("%.2f", number)

    def formatted_amount(number) = format("CHF %.2f", number)

    describe "summary" do
      it "label label #{expected_labels[beitragskategorie]}" do
        expect(presenter.summary.label).to eq expected_labels[beitragskategorie]
      end

      describe "amount" do
        subject(:parts) { presenter.summary.amount.split(" + ") }

        it "includes annual_fee and entry fee without any discount" do
          expect(parts).to have(2).items
          expect(parts.first).to eq "CHF #{format_number(annual_fee)}"
          expect(parts.second).to eq "einmalige Eintrittsgebühr #{formatted_amount(entry_fee)}"
        end

        context "not dealing with main membership" do
          let(:presenter) {
            described_class.new(group, beitragskategorie.to_s, person, main: false)
          }

          it "includes only section fee" do
            expect(parts).to have(1).item
            expect(parts.first).to eq formatted_amount(section_fee)
          end
        end
      end
    end

    describe "lines" do
      subject(:lines) { presenter.lines }

      it "first line contains annual fee of #{annual_fee}" do
        expect(lines.first.label).to eq "jährlicher Beitrag"
        expect(lines.first.amount).to eq formatted_amount(annual_fee)
      end

      context "without discount" do
        before { travel_to(discount_ranges.first.range.begin - 1.day) }

        it "second line contains entry fee of #{entry_fee}" do
          expect(lines.second.label).to eq "+ einmalige Eintrittsgebühr"
          expect(lines.second.amount).to eq formatted_amount(entry_fee)
        end

        it "last line contains total of #{annual_fee + entry_fee}" do
          expect(lines.last.label).to eq "Total erstmalig"
          expect(lines.last.amount).to eq formatted_amount(annual_fee + entry_fee)
        end

        context "not dealing with main membership" do
          let(:presenter) {
            described_class.new(group, beitragskategorie.to_s, person, main: false)
          }

          it "only uses section fee of #{section_fee}" do
            expect(lines).to have(2).items
            expect(lines.last.label).to eq "Total erstmalig"
            expect(lines.last.amount).to eq formatted_amount(section_fee)
          end
        end

        context "living abroad" do
          before { person.update(country: "DE") }

          it "third line contains abroad_fee of #{abroad_fees.values.sum}" do
            expect(lines.third.label).to eq "+ Gebühren Ausland"
            expect(lines.third.amount).to eq formatted_amount(abroad_fees.values.sum)
          end

          it "last line contains total of #{annual_fee + entry_fee + abroad_fees.values.sum}" do
            expect(lines.last.label).to eq "Total erstmalig"
            # rubocop:todo Layout/LineLength
            expect(lines.last.amount).to eq formatted_amount(annual_fee + entry_fee + abroad_fees.values.sum)
            # rubocop:enable Layout/LineLength
          end

          context "not dealing with main membership" do
            let(:presenter) {
              described_class.new(group, beitragskategorie.to_s, person, main: false)
            }

            it "last line contains total of #{section_fee + abroad_fees[:section]}" do
              expect(lines.second.label).to eq "+ Gebühren Ausland"
              expect(lines.second.amount).to eq formatted_amount(abroad_fees[:section])
              expect(lines.third.amount).to eq formatted_amount(section_fee + abroad_fees[:section])
            end
          end
        end
      end

      describe "with discount" do
        discount_ranges.each do |discount|
          context "discount #{discount.percent}% is given inside #{discount.range}" do
            let(:discount_factor) { discount.percent * 0.01 }
            let(:discount_amount) { annual_fee * discount_factor }

            before { travel_to(discount.day) }

            it "second line contains discount of #{discount.calc(annual_fee)}" do
              # rubocop:todo Layout/LineLength
              expect(lines.second.label).to eq "- #{discount.percent}% Rabatt auf den jährlichen Beitrag"
              # rubocop:enable Layout/LineLength
              expect(lines.second.amount).to eq formatted_amount(discount.calc(annual_fee))
            end

            it "pushes down other lines and subtracts discount from total" do
              expect(lines[-2].label).to eq "+ einmalige Eintrittsgebühr"
              expect(lines[-2].amount).to eq formatted_amount(entry_fee)
              expect(lines.last.label).to eq "Total erstmalig"
              # rubocop:todo Layout/LineLength
              expect(lines.last.amount).to eq formatted_amount(discount.apply(annual_fee) + entry_fee)
              # rubocop:enable Layout/LineLength
            end

            context "not dealing with main membership" do
              let(:presenter) {
                described_class.new(group, beitragskategorie.to_s, person, main: false)
              }

              it "second line contains discount of #{discount.calc(section_fee)}" do
                # rubocop:todo Layout/LineLength
                expect(lines.second.label).to eq "- #{discount.percent}% Rabatt auf den jährlichen Beitrag"
                # rubocop:enable Layout/LineLength
                expect(lines.second.amount).to eq formatted_amount(discount.calc(section_fee))
              end
            end

            context "living abroad" do
              before { person.update(country: "DE") }

              if discount.factor < 1
                # rubocop:todo Layout/LineLength
                it "third line contains discounted abroad fees of #{discount.calc(abroad_fees.values.sum)} which is integrated in discount" do
                  # rubocop:enable Layout/LineLength
                  expect(lines.fourth.label).to eq "+ Gebühren Ausland"
                  # rubocop:todo Layout/LineLength
                  expect(lines.fourth.amount).to eq formatted_amount(discount.calc(abroad_fees.values.sum))
                  # rubocop:enable Layout/LineLength
                end
              else

                it "does not show abroad fee if discounted" do
                  expect(lines.map(&:label)).not_to include "+ Gebühren Ausland"
                end
              end

              # rubocop:todo Layout/LineLength
              it "last line contains total of #{discount.apply(annual_fee + abroad_fees.values.sum) + entry_fee}" do
                # rubocop:enable Layout/LineLength
                expect(lines.last.label).to eq "Total erstmalig"
                # rubocop:todo Layout/LineLength
                expect(lines.last.amount).to eq formatted_amount(discount.apply(annual_fee + abroad_fees.values.sum) + entry_fee)
                # rubocop:enable Layout/LineLength
              end

              context "not dealing with main membership" do
                let(:presenter) {
                  described_class.new(group, beitragskategorie.to_s, person, main: false)
                }

                if discount.factor < 1
                  # rubocop:todo Layout/LineLength
                  it "third line contains discounted abroad section fee of #{discount.calc(abroad_fees[:section])} which is integrated in discount" do
                    # rubocop:enable Layout/LineLength
                    expect(lines.third.label).to eq "+ Gebühren Ausland"
                    # rubocop:todo Layout/LineLength
                    expect(lines.third.amount).to eq formatted_amount(discount.calc(abroad_fees[:section]))
                    # rubocop:enable Layout/LineLength
                  end
                else

                  it "does not show abroad fee if discounted" do
                    expect(lines.map(&:label)).not_to include "+ Gebühren Ausland"
                  end
                end

                # rubocop:todo Layout/LineLength
                it "last line contains total of #{discount.apply(section_fee + abroad_fees[:section])}" do
                  # rubocop:enable Layout/LineLength
                  expect(lines.last.label).to eq "Total erstmalig"
                  # rubocop:todo Layout/LineLength
                  expect(lines.last.amount).to eq formatted_amount(discount.apply(section_fee + abroad_fees[:section]))
                  # rubocop:enable Layout/LineLength
                end
              end
            end
          end
        end
      end
    end
  end

  it_behaves_like "signup_fee_presenter", beitragskategorie: :adult, annual_fee: 127,
    entry_fee: 20, section_fee: 42, abroad_fees: {section: 13, magazin: 10}

  context "existing person with membership" do
    let(:presenter) { described_class.new(group, :adult, people(:mitglied)) }

    it "does not include entry fee in summary amount" do
      expect(presenter.summary.amount).not_to include "Eintrittsgebühr"
    end

    it "does not include entry fee in presenter lines" do
      expect(presenter.lines.map(&:label)).not_to include "+ einmalige Eintrittsgebühr"
    end
  end

  context "existing person without membership" do
    let(:presenter) { described_class.new(group, :adult, people(:abonnent)) }

    it "does include entry fee in summary amount" do
      expect(presenter.summary.amount).to include "Eintrittsgebühr"
    end

    it "does include entry fee in presenter lines" do
      expect(presenter.lines.map(&:label)).to include "+ einmalige Eintrittsgebühr"
    end
  end

  it_behaves_like "signup_fee_presenter", beitragskategorie: :family, annual_fee: 179,
    entry_fee: 35, section_fee: 84, abroad_fees: {section: 13, magazin: 10}

  it_behaves_like "signup_fee_presenter", beitragskategorie: :youth, annual_fee: 76, entry_fee: 15,
    section_fee: 21, abroad_fees: {section: 13, magazin: 10}
end
