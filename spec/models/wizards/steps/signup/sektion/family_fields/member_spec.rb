# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::Sektion::FamilyFields::Member do
  let(:wizard) { instance_double(Wizards::Signup::SektionWizard, requires_adult_consent?: false, requires_policy_acceptance?: false) }
  let(:family) { instance_double(Wizards::Steps::Signup::Sektion::FamilyFields, emails: %w[test@example.com]) }
  subject(:member) { described_class.new }

  let(:required_attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      birthday: "01.01.2000",
      email: "test2@example.com",
      phone_number: "0791234567"
    }
  }

  describe "::human_attribute_name" do
    it "reads from person" do
      expect(described_class.human_attribute_name(:first_name)).to eq "Vorname"
    end
  end

  describe "validations" do
    it "is valid if required attrs are set" do
      member.attributes = required_attrs
      expect(member).to be_valid
    end

    it "is valid without email or phone_number if person is not an adult" do
      member.attributes = required_attrs.except(:email, :phone_number)
      member.birthday = 10.years.ago.to_date
      expect(member).to be_valid
    end

    it "validates presence of each required attr" do
      expect(member).not_to be_valid
      (required_attrs.keys - [:email, :phone_number]).each do |attr|
        expect(member.errors.attribute_names).to include(attr)
      end
    end

    describe "phone_number" do
      it "must be have a valid format" do
        member.phone_number = "test"
        expect(member).not_to be_valid
        expect(member.errors[:phone_number]).to eq ["ist nicht gültig"]
      end
    end

    describe "email" do
      it "must not be taken by others" do
        member.email = "e.hillary@hitobito.example.com"
        expect(member).not_to be_valid
        expect(member.errors.full_messages).to include "E-Mail ist bereits vergeben. Die E-Mail muss eindeutig sein pro Person."
      end
    end

    describe "birthday" do
      it "validates user is not below 6 years" do
        member.attributes = required_attrs.merge(birthday: 1.year.ago.to_date)
        expect(member).not_to be_valid
        expect(member.errors.full_messages).to eq ["Person muss 6 Jahre oder älter sein"]
      end

      it "accepts birthday on last day 17 years ago but rejects on first day 18 years ago" do
        member.attributes = required_attrs.merge(birthday: 17.years.ago.end_of_year.to_date)
        expect(member).to be_valid

        member.attributes = required_attrs.merge(birthday: 18.years.ago.beginning_of_year.to_date)
      end

      it "rejects birthday on last day 21 years ago but accepts on first day 22 years ago" do
        member.attributes = required_attrs.merge(birthday: 21.years.ago.end_of_year.to_date)
        expect(member).not_to be_valid
        expect(member.errors.full_messages).to eq ["Geburtstag Jugendliche im Alter von 18 bis 21 Jahre können nicht\nin einer Familienmitgliedschaft aufgenommen werden.\n"]

        member.attributes = required_attrs.merge(birthday: 22.years.ago.beginning_of_year.to_date)
        expect(member).to be_valid
      end
    end
  end

  it "attributes builds with nested phone_number attributes" do
    member.attributes = required_attrs.merge(phone_number: "0791234567")

    expect(member.person_attributes).to eq required_attrs
      .except(:phone_number)
      .merge(
        birthday: Date.new(2000, 1, 1),
        phone_numbers_attributes: [{label: "Mobil", number: "0791234567"}]
      )
  end
end
