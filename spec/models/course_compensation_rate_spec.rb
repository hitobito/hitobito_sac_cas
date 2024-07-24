# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe CourseCompensationRate do
  subject(:model) { described_class.new }

  before { travel_to(Date.new(2024, 5, 31)) }

  context "validations" do
    context "course compensation category uniqueness" do
      let!(:category) { Fabricate(:course_compensation_category) }
      let!(:another_category) { Fabricate(:course_compensation_category) }
      let!(:present) {
        Fabricate(:course_compensation_rate, course_compensation_category: category,
          valid_from: 1.month.ago, valid_to: Time.zone.today)
      }

      subject(:rate) {
        Fabricate.build(:course_compensation_rate, course_compensation_category: category)
      }

      context "with same category" do
        it "is invalid with validity period inside present validity period" do
          rate.valid_from = 2.weeks.ago
          rate.valid_to = 1.week.ago
          expect(rate).to_not be_valid
          expect(rate.errors.full_messages).to match_array(["Vergütungskategorie darf pro Validitätsperiode nur ein Vergütungsansatz referenzieren."])
        end

        it "is invalid with validity end inside present validity period" do
          rate.valid_from = 2.months.ago
          rate.valid_to = 2.weeks.ago
          expect(rate).to_not be_valid
          expect(rate.errors.full_messages).to match_array(["Vergütungskategorie darf pro Validitätsperiode nur ein Vergütungsansatz referenzieren."])
        end

        it "is invalid with validity start inside present validity period" do
          rate.valid_from = 1.week.ago
          rate.valid_to = 1.month.from_now
          expect(rate).to_not be_valid
          expect(rate.errors.full_messages).to match_array(["Vergütungskategorie darf pro Validitätsperiode nur ein Vergütungsansatz referenzieren."])
        end

        it "is invalid with endless validity period that overlaps present validity period" do
          rate.valid_from = 2.months.ago
          rate.valid_to = nil
          expect(rate).to_not be_valid
          expect(rate.errors.full_messages).to match_array(["Vergütungskategorie darf pro Validitätsperiode nur ein Vergütungsansatz referenzieren."])
        end

        it "is invalid with endless validity period that overlaps present endless validity period" do
          present.update!(valid_to: nil)
          rate.valid_from = 2.weeks.ago
          rate.valid_to = nil
          expect(rate).to_not be_valid
          expect(rate.errors.full_messages).to match_array(["Vergütungskategorie darf pro Validitätsperiode nur ein Vergütungsansatz referenzieren."])
        end

        it "is valid with validity period outside present validity period" do
          rate.valid_from = 1.week.from_now
          rate.valid_to = 1.month.from_now
          expect(rate).to be_valid
        end

        it "is valid with validity period outside present validity period, when present validity is endless" do
          present.update!(valid_to: nil)
          rate.valid_from = 3.month.ago
          rate.valid_to = 1.month.ago
          expect(rate).to be_valid
        end
      end

      context "change validity period" do
        it "is possible and validation doesn't trigger itself" do
          present.valid_from = 2.weeks.ago
          present.valid_to = Time.zone.today

          expect(present).to be_valid
        end
      end

      context "with different category" do
        subject(:rate) { Fabricate.build(:course_compensation_rate) }

        it "is valid with validity period inside present validity period" do
          rate.valid_from = 2.weeks.ago
          rate.valid_to = 1.week.ago
          rate.course_compensation_category = another_category

          expect(rate).to be_valid
        end
      end
    end
  end
end
