# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::People::PersonEntry do
  let(:group) { Group::ExterneKontakte.new(id: 1) }
  let(:source) { SacImports::CsvSource::SOURCES[:NAV1] }
  let(:data) { source.new(**row.reverse_merge(source.members.index_with(nil))) }

  let(:row) do
    {
      navision_id: 123,
      first_name: "Max",
      last_name: "Muster",
      email: "max.muster@example.com",
      gender: "0",
      language: "DES",
      birthday: 40.years.ago.to_date
    }
  end
  let(:existing_emails) { Concurrent::Set.new(Person.pluck(:email).compact) }

  subject(:entry) { described_class.new(data, group, existing_emails) }

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

    context "without group" do
      let(:group) { nil }

      it "is invalid without group" do
        expect(entry).not_to be_valid
        expect(entry.errors).to eq "Rollen ist nicht gültig, Group muss ausgefüllt werden"
      end
    end
  end

  describe "company attributes" do
    subject(:person) { entry.person }

    it "sets various attributes via through values" do
      row[:first_name] = :first
      row[:last_name] = "Puzzle GmbH"
      row[:person_type] = "2"
      row[:language] = "DES"
      expect(person.first_name).to be_nil
      expect(person.last_name).to be_nil
      expect(person.gender).to be_nil
      expect(person.language).to eq "de"
      expect(person.company).to eq true
      expect(person.company_name).to eq "first Puzzle GmbH"
      expect(person).to be_valid
    end
  end

  describe "person attributes" do
    subject(:person) { entry.person }

    it "sets confirmed_at to skip devise confirmation email" do
      expect(person.confirmed_at).to eq Time.zone.at(0)
    end

    it "sets various attributes via through values" do
      row[:first_name] = :first
      row[:last_name] = :last
      row[:zip_code] = 3000
      row[:town] = :town
      row[:country] = "CH"
      row[:birthday] = "1.1.2000"
      row[:gender] = "0"
      row[:language] = "DES"
      expect(person.first_name).to eq "first"
      expect(person.last_name).to eq "last"
      expect(person.zip_code).to eq "3000"
      expect(person.town).to eq "town"
      expect(person.country).to eq "CH"
      expect(person.gender).to eq "m"
      expect(person.language).to eq "de"
      expect(person.company).to eq false
      expect(person.birthday).to eq Date.new(2000, 1, 1)
      expect(person).to be_valid
    end

    it "sets address attributes" do
      row[:address_care_of] = "test"
      row[:street_name] = "landweg 1a"
      row[:postbox] = "postfach 3000"

      expect(person.address_care_of).to eq "test"
      expect(person.street).to eq "landweg"
      expect(person.housenumber).to eq "1a"
      expect(person.postbox).to eq "postfach 3000"

      expect(person.address).to eq "landweg 1a"
    end

    it "sets street and housenumber if housenumber in own column" do
      row[:street_name] = "landweg"
      row[:housenumber] = "1a"

      expect(person.street).to eq "landweg"
      expect(person.housenumber).to eq "1a"

      expect(person.address).to eq "landweg 1a"
    end

    it "language defaults to de" do
      row[:language] = nil
      expect(person.language).to eq "de"
    end

    context "when person with the email already exists" do
      before { Fabricate(:person, email: "max.muster@example.com") }

      it "still imports the person, but with a warning" do
        expect(person.email).to be_nil
        expect(entry).to be_valid
        expect(entry.warning).to include("additional_email")
        expect { entry.import! }
          .to change(AdditionalEmail, :count).by(1)
          .and change(Person, :count).by(1)
      end

      it "does not import" do
        expect(person.email).to eq "max.muster@example.com"
        expect { entry.import! }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "phone numbers" do
    subject(:numbers) { entry.person.phone_numbers }

    it "sets phone numbers" do
      row[:phone] = "079 12 123 10"
      expect(numbers).to have(1).items
      expect(numbers[0][:label]).to eq "Hauptnummer"
      expect(numbers[0][:number]).to eq "079 12 123 10"
      expect(numbers.collect(&:public).uniq).to eq [true]
    end

    it "ignores invalid phone numbers" do
      row[:phone] = "123"
      expect(numbers).to have(0).item
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
