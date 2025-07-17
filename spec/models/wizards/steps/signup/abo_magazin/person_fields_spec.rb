# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::AboMagazin::PersonFields do
  let(:wizard) { instance_double(Wizards::Signup::AboMagazinWizard, current_user: nil) }
  subject(:step) { described_class.new(wizard) }

  let(:required_attrs) {
    {
      gender: "m",
      first_name: "Max",
      last_name: "Muster",
      birthday: "01.01.2000",
      street: "Musterplatz",
      housenumber: "23",
      town: "Zurich",
      zip_code: "8000"
    }
  }

  describe "validations" do
    it "validates presence of each required attr" do
      expect(step).not_to be_valid
      required_attrs.keys.each do |attr|
        expect(step.errors.attribute_names).to include(attr)
      end
    end

    describe "company" do
      before do
        step.attributes = required_attrs.merge(company: true, company_name: "Dummy, Inc.")
      end

      it "is valid" do
        expect(step).to be_valid
      end

      it "is valid with nil gender" do
        step.gender = nil
        expect(step).to be_valid
      end

      it "is valid with nil birthday" do
        step.birthday = nil
        expect(step).to be_valid
      end

      it "is invalid with blank company_name" do
        step.company_name = ""
        expect(step).not_to be_valid
        expect(step.errors.full_messages).to eq ["Firmenname muss ausgefüllt werden"]
      end
    end
  end
end
