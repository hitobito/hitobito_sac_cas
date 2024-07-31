# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::PersonFields do
  let(:wizard) { instance_double(Wizards::Signup::SektionWizard, requires_adult_consent?: false, requires_policy_acceptance?: false) }
  subject(:form) { described_class.new(wizard) }

  let(:required_attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      birthday: "01.01.2000"
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
    end
  end

  it "sets country default to ch" do
    expect(form.country).to eq "CH"
  end

  it "does not requires_policy_acceptance?" do
    expect(form.country).to eq "CH"
  end

  it "attributes builds with nested phone_number attributes" do
    form.attributes = required_attrs

    expect(form.person_attributes).to eq required_attrs
      .except(:phone_number)
      .merge(country: "CH", birthday: Date.new(2000, 1, 1))
  end
end
