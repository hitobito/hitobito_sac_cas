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
      emergency_contact_1_name: "Tina Muster",
      emergency_contact_1_phone: "+41 76 123 45 67",
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
        "Mindestens eine Telefonnummer muss aufgefüllt werden"
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

  context "emergency contacts" do
    let(:attrs_without_emergency_contact) {
      attrs.except("emergency_contact_1_name", "emergency_contact_1_phone")
    }

    it "requires first emergency contact for courses" do
      contact_data = build(attrs_without_emergency_contact)

      expect(contact_data).not_to be_valid
      expect(contact_data.errors[:emergency_contact_1_name]).to eq ["muss ausgefüllt werden"]
      expect(contact_data.errors[:emergency_contact_1_phone]).to eq ["muss ausgefüllt werden"]
    end

    it "requires first emergency contact for tours" do
      event = Fabricate.build(:sac_tour)
      contact_data = Event::ParticipationContactData.new(event, person.clone,
        attrs_without_emergency_contact)

      expect(contact_data).not_to be_valid
      expect(contact_data.errors[:emergency_contact_1_name]).to be_present
      expect(contact_data.errors[:emergency_contact_1_phone]).to be_present
    end

    it "does not require emergency contacts for other events" do
      event = Fabricate.build(:event)
      contact_data = Event::ParticipationContactData.new(event, person.clone,
        attrs_without_emergency_contact)

      expect(contact_data).to be_valid
    end

    it "does not require second emergency contact" do
      contact_data = build(attrs)
      expect(person.emergency_contact_2_name).to be_blank

      expect(contact_data).to be_valid
    end

    it "validates the emergency contact phone number" do
      contact_data = build(attrs.merge(emergency_contact_1_phone: "abc"))

      expect(contact_data).not_to be_valid
      expect(contact_data.person.errors[:emergency_contact_1_phone]).to include("ist nicht gültig")
    end

    describe "#mark_as_required?" do
      it "marks first emergency contact as required for courses" do
        contact_data = build(attrs)

        expect(contact_data.mark_as_required?(:emergency_contact_1_name)).to be true
        expect(contact_data.mark_as_required?(:emergency_contact_1_phone)).to be true
        expect(contact_data.mark_as_required?(:emergency_contact_2_name)).to be false
        expect(contact_data.mark_as_required?(:emergency_contact_2_phone)).to be false
      end

      it "does not mark emergency contacts as required for other events" do
        event = Fabricate.build(:event)
        contact_data = Event::ParticipationContactData.new(event, person.clone, attrs)

        expect(contact_data.mark_as_required?(:emergency_contact_1_name)).to be false
        expect(contact_data.mark_as_required?(:phone_numbers)).to be true
      end
    end
  end

  context "phone_number" do
    it "can be added" do
      expect(person.phone_numbers).to be_empty

      contact_data = build(attrs)
      expect(contact_data).to be_valid

      expect { contact_data.save }
        .to change { person.phone_numbers.count }.by(1)
      expect(person.phone_number_mobile.number).to eq "+41 79 123 45 56"
    end

    it "can be removed" do
      existing_number = person.create_phone_number_landline(number: "044 112 00 00")
      expect(person.phone_numbers.count).to eq 1

      contact_data = build(attrs.merge(
        # remove the single existing number
        phone_number_landline_attributes: {id: existing_number.id, number: ""}
      ))
      expect(contact_data).to be_valid

      expect { contact_data.save }
        .to change { person.reload.phone_number_landline }.to(nil)
    end

    it "can be updated" do
      existing_number = person.create_phone_number_landline!(number: "044 112 00 00")
      expect(person.phone_numbers.count).to eq 1

      contact_data = build(attrs.merge(
        phone_number_landline_attributes: {id: existing_number.id, number: "044 112 00 01"}
      ))
      expect(contact_data).to be_valid

      expect { contact_data.save }
        .to change { person.reload.phone_number_landline.number }.to("+41 44 112 00 01")
    end
  end

  def build(attributes)
    Event::ParticipationContactData.new(event.clone, person.clone, attributes)
  end
end
