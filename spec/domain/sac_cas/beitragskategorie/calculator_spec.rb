# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacCas::Beitragskategorie::Calculator do
  def category(age: nil, household: false)
    described_class.new(person(age, household)).calculate
  end

  def person(age, household = false, test_reference_date = Time.current)
    birthday = test_reference_date - age.years if age
    household_key = "household" if household
    Fabricate.build(:person, birthday: birthday, household_key: household_key)
  end

  context "#family_age?" do
    it "returns true for adult" do
      [23, 99].each do |age|
        calculator = described_class.new(person(age))
        expect(calculator.adult?).to eq(true), "expected #{age} to be adult"
        expect(calculator.family_age?).to eq(true), "expected #{age} to be family_age"
      end
    end

    it "returns true for child" do
      [6, 17].each do |age|
        calculator = described_class.new(person(age))
        expect(calculator.child?).to eq(true), "expected #{age} to be child"
        expect(calculator.family_age?).to eq(true), "expected #{age} to be family_age"
      end
    end

    it "returns false for person younger than 6 years" do
      calculator = described_class.new(person(5))
      expect(calculator.family_age?).to eq(false)
    end

    it "returns false for youth" do
      [18, 22].each do |age|
        calculator = described_class.new(person(age))
        expect(calculator.family_age?).to eq(false), "expected #{age} to be youth"
      end
    end

    it "returns false for person without birthday" do
      calculator = described_class.new(person(nil))
      expect(calculator.family_age?).to eq(false)
    end
  end

  context "#calculate" do
    it "returns adult for person with 23 years or older" do
      expect(category(age: 23)).to eq(:adult)
      expect(category(age: 99)).to eq(:adult)
    end

    it "returns youth for person between 6 and 22 years not in a family" do
      expect(category(age: 6)).to eq(:youth)
      expect(category(age: 15)).to eq(:youth)
      expect(category(age: 22)).to eq(:youth)
    end

    it "returns family for adult family member" do
      expect(category(age: 23, household: true)).to eq(:family)
      expect(category(age: 99, household: true)).to eq(:family)
    end

    it "returns youth for person between 18 and 22 if in same household with others" do
      expect(category(age: 18, household: true)).to eq(:youth)
      expect(category(age: 22, household: true)).to eq(:youth)
    end

    it "returns nil for person younger than 6 years" do
      expect(category(age: 5)).to eq(nil)
    end

    it "returns nil for person without birthday" do
      expect(category(age: nil)).to eq(nil)
    end

    it "respects reference_date" do
      person = person(15, false, Time.zone.today)
      expect(described_class.new(person, reference_date: Date.current).calculate).to eq(:youth)
      expect(described_class.new(person,
        reference_date: 8.years.from_now - 1.day).calculate).to eq(:youth)
      expect(described_class.new(person, reference_date: 8.years.from_now).calculate).to eq(:adult)
    end

    context "not for sac family" do
      def category(age: nil, household: false)
        described_class.new(person(age, household)).calculate(for_sac_family: false)
      end

      it "returns adult for person with 23 years or older" do
        expect(category(age: 23)).to eq(:adult)
        expect(category(age: 99)).to eq(:adult)
      end

      it "returns youth for person between 6 and 22 years not in a family" do
        expect(category(age: 6)).to eq(:youth)
        expect(category(age: 15)).to eq(:youth)
        expect(category(age: 22)).to eq(:youth)
      end

      it "returns adult for adult family member" do
        expect(category(age: 23, household: true)).to eq(:adult)
        expect(category(age: 99, household: true)).to eq(:adult)
      end

      it "returns youth for person between 18 and 22 if in same household with others" do
        expect(category(age: 18, household: true)).to eq(:youth)
        expect(category(age: 22, household: true)).to eq(:youth)
      end

      it "returns nil for person younger than 6 years" do
        expect(category(age: 5)).to eq(nil)
      end

      it "returns nil for person without birthday" do
        expect(category(age: nil)).to eq(nil)
      end

      it "respects reference_date" do
        person = person(15, false)
        expect(described_class.new(person, reference_date: Date.current).calculate).to eq(:youth)
        expect(described_class.new(person,
          reference_date: 8.years.from_now - 1.day).calculate).to eq(:youth)
        expect(described_class.new(person,
          reference_date: 8.years.from_now).calculate).to eq(:adult)
      end
    end
  end
end
