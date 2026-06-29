# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::BirthdayValidator do
  let(:person) { people(:mitglied) }
  let(:current_user) { people(:mitglied) }
  let(:validator) { described_class.new(person, current_user) }

  before do
    travel_to "06.06.2025"
  end

  it "adds no error when born in middle of cutoff year" do
    person.update!(birthday: Date.parse("06.06.2019"))
    expect { validator.validate_birthday_range }.not_to throw_symbol(:abort)
    expect(person.errors[:birthday]).to be_empty
  end

  it "adds no error when born on last day of cutoff year" do
    person.update!(birthday: Date.parse("31.12.2019"))
    expect { validator.validate_birthday_range }.not_to throw_symbol(:abort)
    expect(person.errors[:birthday]).to be_empty
  end

  it "adds error when born on first day after cutoff year" do
    person.update!(birthday: Date.parse("01.01.2020"))
    expect { validator.validate_birthday_range }.to throw_symbol(:abort)
    expect(person.errors[:birthday]).to eq ["muss vor dem 31.12.2019 liegen."]
  end

  it "adds no error when exactly 119 years and 364 days old" do
    person.update!(birthday: Date.parse("07.06.1905"))
    expect { validator.validate_birthday_range }.not_to throw_symbol(:abort)
    expect(person.errors[:birthday]).to be_empty
  end

  it "adds error when over 120 years old" do
    person.update!(birthday: Date.parse("05.06.1905"))
    expect { validator.validate_birthday_range }.to throw_symbol(:abort)
    expect(person.errors[:birthday]).to eq ["muss nach dem 06.06.1905 liegen."]
  end

  context "backoffice" do
    let(:current_user) { people(:admin) }

    it "adds error if blan" do
      person.birthday = nil
      expect { validator.validate! }.to throw_symbol(:abort)
      expect(person.errors[:birthday]).to eq ["muss ausgefüllt werden"]
    end
  end

  describe "#too_young?" do
    subject(:validator) { described_class.new(person) }

    it "returns false when birthday is blank" do
      person.birthday = nil
      expect(validator.too_young?).to be false
    end

    it "returns false when born on last day of cutoff year" do
      person.birthday = Date.new(2019, 12, 31)
      expect(validator.too_young?).to be false
    end

    it "returns true when born on first day after cutoff year" do
      person.birthday = Date.new(2020, 1, 1)
      expect(validator.too_young?).to be true
    end

    it "accepts a reference date and uses end of that year as cutoff" do
      person.birthday = Date.new(2019, 1, 1)
      expect(validator.too_young?(Date.new(2024, 1, 1))).to be true
      expect(validator.too_young?(Date.new(2025, 1, 1))).to be false
    end
  end

  describe "#too_old?" do
    subject(:validator) { described_class.new(person) }

    it "returns false when birthday is blank" do
      person.birthday = nil
      expect(validator.too_old?).to be false
    end

    it "returns false when born exactly 120 years ago today" do
      person.birthday = Date.new(1905, 6, 6)
      expect(validator.too_old?).to be false
    end

    it "returns true when born more than 120 years ago" do
      person.birthday = Date.new(1905, 6, 5)
      expect(validator.too_old?).to be true
    end
  end
end
