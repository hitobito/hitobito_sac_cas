# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Import::PersonEntry do
  let(:emails) { [] }
  let(:group) { Group::ExterneKontakte.new(id: 1) }
  let(:row) do
    Import::PeopleImporter.headers.keys.index_with { |_symbol| nil }.merge(
      navision_id: 123,
      first_name: "Max",
      last_name: "Muster",
      email: "max.muster@example.com",
      gender: "Weiblich",
      language: "DES",
      birthday: 40.years.ago.to_date
    )
  end

  subject(:entry) { described_class.new(row, group: group, emails: emails) }

  before { travel_to(Time.zone.local(2022, 10, 20, 11, 11)) }

  it "#person does not persist person" do
    expect(entry).to be_valid
    expect { entry.person }.not_to(change { Person.count })
  end

  describe "validations" do
    it "is valid with birthday 6 years ago" do
      row[:birthday] = 6.years.ago
      expect(entry).to be_valid
      expect(entry.errors).to be_empty
    end

    it "is valid with birthday less than 6 years ago" do
      row[:birthday] = (5.years + 11.months).ago
      expect(entry).to be_valid
      expect(entry.errors).to be_empty
    end

    it "is valid without birthday" do
      row[:birthday] = nil
      expect(entry).to be_valid
      expect(entry.errors).to be_empty
    end

    it "is invalid without group" do
      person = described_class.new(row.merge(birthday: 6.years.ago), group: nil)
      expect(person).not_to be_valid
      expect(person.errors).to eq "Muster Max (123): Rollen ist nicht gültig, Group muss ausgefüllt werden"
    end
  end

  describe "person attributes" do
    subject(:person) { entry.person }

    it "sets confirmed_at to skip devise confirmation email" do
      expect(person.confirmed_at).to eq Time.zone.at(0)
    end

    it "assigns attributes to existing person found by navision_id" do
      Fabricate(:person, id: 123)
      row[:navision_id] = 123
      row[:first_name] = :test
      expect(person.first_name).to eq "test"
      expect(person.primary_group).to eq group
    end

    it "sets various attributes via through values" do
      row[:first_name] = :first
      row[:last_name] = :last
      row[:zip_code] = 3000
      row[:town] = :town
      row[:country] = "CH"
      row[:birthday] = "1.1.2000"
      row[:gender] = "Männlich"
      row[:language] = "DES"
      expect(person.first_name).to eq "first"
      expect(person.last_name).to eq "last"
      expect(person.zip_code).to eq "3000"
      expect(person.town).to eq "town"
      expect(person.country).to eq "CH"
      expect(person.gender).to eq "m"
      expect(person.language).to eq "de"
      expect(person.birthday).to eq Date.new(2000, 1, 1)
      expect(person).to be_valid
    end

    it "sets address attributes" do
      row[:address_supplement] = "test"
      row[:address] = "Landweg 1a"
      row[:postfach] = "Postfach 3000"

      expect(person.address_care_of).to eq "test"
      expect(person.street).to eq "Landweg"
      expect(person.housenumber).to eq "1a"
      expect(person.postbox).to eq "Postfach 3000"

      expect(person.address).to eq "Landweg 1a"
    end

    it "language defaults to de" do
      row[:language] = nil
      expect(person.language).to eq "de"
    end

    it "sets email to nil if email is included in passed emails array" do
      emails << "test@example.com"
      row[:email] = "test@example.com"
      expect(entry).to be_valid
      expect(entry.person.email).to be_blank
    end
  end

  describe "phone numbers" do
    subject(:numbers) { entry.person.phone_numbers }

    it "sets phone numbers" do
      row[:phone] = "079 12 123 10"
      row[:phone_mobile] = "079 12 123 11"
      row[:phone_direct] = "079 12 123 12"
      expect(numbers).to have(3).items

      expect(numbers[0][:label]).to eq "Privat"
      expect(numbers[1][:label]).to eq "Mobil"
      expect(numbers[2][:label]).to eq "Direkt"
      expect(numbers[0][:number]).to eq "079 12 123 10"
      expect(numbers[1][:number]).to eq "079 12 123 11"
      expect(numbers[2][:number]).to eq "079 12 123 12"

      expect(numbers.collect(&:public).uniq).to eq [true]
    end

    it "ignores invalid phone numbers" do
      row[:phone] = "123"
      row[:phone_mobile] = "079 12 34 560"
      expect(numbers).to have(1).item
      expect(numbers.first.number).to eq "079 12 34 560"
    end
  end

  describe "roles" do
    subject(:role) { entry.person.roles.first }

    it "sets expected type and group" do
      expect(role.group).to eq group
      expect(role.type).to eq "Group::ExterneKontakte::Kontakt"
      expect(role).to be_valid
    end
  end
end
