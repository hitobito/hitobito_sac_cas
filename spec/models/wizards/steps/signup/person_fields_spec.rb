# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::PersonFields do
  let(:wizard) { instance_double(Wizards::Signup::SektionWizard, requires_adult_consent?: false, requires_policy_acceptance?: false, current_user: nil) }
  subject(:form) { described_class.new(wizard) }

  let(:required_attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      street: "Musterplatz",
      housenumber: "23",
      town: "Zurich",
      zip_code: "8000"
    }
  }

  describe "::human_attribute_name" do
    it "reads from person" do
      expect(described_class.human_attribute_name(:first_name)).to eq "Vorname"
    end
  end

  describe "validations" do
    it "is valid if required attrs are set" do
      form.attributes = required_attrs
      expect(form).to be_valid
    end

    it "validates presence of each required attr" do
      expect(form).not_to be_valid
      required_attrs.keys.each do |attr|
        expect(form.errors.attribute_names).to include(attr)
      end
    end

    describe "gender" do
      it "accepts _nil gender" do
        form.attributes = required_attrs.merge(gender: "_nil")
        expect(form).to be_valid
        expect(form.gender_label).to eq "divers"
      end
    end

    describe "phone_number" do
      it "must be have a valid format" do
        form.phone_number = "test"
        expect(form).not_to be_valid
        expect(form.errors[:phone_number]).to eq ["ist nicht gültig"]
      end
    end

    describe "birthday" do
      it "validates user is old enough" do
        form.attributes = required_attrs.merge(birthday: 1.year.ago.to_date)
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Person muss 6 Jahre oder älter sein"]
      end

      it "validates user is not too old" do
        travel_to(Date.new(2025, 5, 27)) do
          form.attributes = required_attrs.merge(birthday: "01.01.1622")
          expect(form).not_to be_valid
          expect(form.errors.full_messages).to eq ["Person muss 199 Jahre oder jünger sein"]
        end
      end
    end

    describe "zip_code" do
      it "validates swiss zip code format" do
        form.attributes = required_attrs.merge(zip_code: "123")
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["PLZ ist nicht gültig"]
      end

      it "validates other zip code formats" do
        form.attributes = required_attrs.merge(zip_code: "123", country: "US")
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["PLZ ist nicht gültig"]
        form.zip_code = 90210
        expect(form).to be_valid
      end
    end
  end

  it "sets country default to ch" do
    expect(form.country).to eq "CH"
  end

  it "does not requires_policy_acceptance?" do
    expect(form.country).to eq "CH"
  end

  describe "#person_attributes" do
    it "builds with nested phone_number attributes" do
      form.attributes = required_attrs

      expect(form.person_attributes).to eq required_attrs
        .except(:phone_number)
        .merge(country: "CH")
    end

    it "converts gender value of '_nil' to nil" do
      form.attributes = required_attrs.merge(gender: "_nil")

      expect(form.person_attributes[:gender]).to be_nil
    end
  end

  context "with current user" do
    let(:params) { {} }
    let(:person) { people(:abonnent) }
    let(:wizard) { instance_double(Wizards::Signup::SektionWizard, requires_adult_consent?: false, requires_policy_acceptance?: false, current_user: person) }

    subject(:form) { described_class.new(wizard, **params) }

    it "reads attributes from current_user" do
      person.attributes = {postbox: 1234, address_care_of: "tbd", country: "US"}
      expect(form.id).to eq person.id
      expect(form.gender).to eq "w"
      expect(form.first_name).to eq "Magazina"
      expect(form.last_name).to eq "Leseratte"
      expect(form.birthday).to eq Date.new(1993, 6, 12)
      expect(form.street).to eq "Ophovenerstrasse"
      expect(form.housenumber).to eq "79a"
      expect(form.postbox).to eq "1234"
      expect(form.address_care_of).to eq "tbd"
      expect(form.zip_code).to eq "2843"
      expect(form.town).to eq "Neu Carlscheid"
      expect(form.country).to eq "US"
      expect(form.phone_number).to be_blank
    end

    it "reads nil gender into I18nEnum::NIL_KEY" do
      person.gender = nil
      expect(form.gender).to eq "_nil"
    end

    it "reads phone_number if present" do
      number = person.phone_numbers.create!(label: "mobile", number: "0791234567")
      expect(form.phone_number).to eq "+41 79 123 45 67"
      expect(form.person_attributes[:phone_number_mobile_attributes][:id]).to eq number.id
    end

    it "params override values read from person" do
      params[:first_name] = "Test"
      expect(form.first_name).to eq "Test"
      expect(form.last_name).to eq "Leseratte"
    end
  end
end
