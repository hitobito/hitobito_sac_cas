# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationContactData do
  let(:event) { Fabricate.build(:course) }
  let(:person) { Fabricate.create(:person) }

  let(:attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      street: "Musterplatz",
      housenumber: "23",
      email: "max.muster@example.com",
      zip_code: "8000",
      town: "Zürich",
      country: "CH",
      birthday: "01.01.1980",
      phone_number_mobile_attributes: {
        number: "+41 79 123 45 56"
      }
    }.with_indifferent_access
  }

  describe "::validations" do
    it "is valid if required attributes are set" do
      expect(build(attrs)).to be_valid
    end

    it "is invalid if all numbers are blank" do
      attrs[:phone_number_mobile_attributes]["number"] = ""
      contact_data = build(attrs)
      expect(contact_data).not_to be_valid
      expect(contact_data.errors.full_messages).to eq [
        "Telefonnummer muss ausgefüllt werden"
      ]
    end

    it "is invalid if phone number is invalid" do
      attrs[:phone_number_mobile_attributes]["number"] = "test"
      contact_data = build(attrs)
      expect(contact_data).not_to be_valid
      expect(contact_data.errors.full_messages).to eq [
        "Mobiltelefon ist nicht gültig"
      ]
      expect(contact_data.person.phone_number_mobile).to have(1).error_on(:number)
    end
  end

  it "can handle deletion and mutation of phone-number" do
    attrs.delete(:phone_number_mobile_attributes)
    existing_number = person.create_phone_number_landline(number: "044 112 00 00")
    expect(person.phone_numbers.count).to eq 1

    contact_data = build(attrs.merge(
      # remove the single existing number
      phone_number_landline_attributes: {id: existing_number.id, number: ""}
    ))
    expect(contact_data).not_to be_valid

    contact_data = build(attrs.merge(
      # remove the existing number, add another one
      phone_number_landline_attributes: {id: existing_number.id, number: ""},
      phone_number_mobile_attributes: {id: nil, number: "079 123 45 67"}
    ))
    expect(contact_data).to be_valid

    contact_data = build(attrs.merge(
      # add another number besides the existing one
      phone_number_mobile_attributes: {id: nil, number: "079 123 45 67"}
    ))
    expect(contact_data).to be_valid
  end

  def build(attributes)
    Event::ParticipationContactData.new(event, person, attributes)
  end
end
