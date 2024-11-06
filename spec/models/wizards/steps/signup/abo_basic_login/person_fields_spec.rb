# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::AboBasicLogin::PersonFields do
  let(:wizard) { instance_double(Wizards::Signup::AboBasicLoginWizard) }
  subject(:form) { described_class.new(wizard) }

  let(:required_attrs) {
    {
      gender: "m",
      first_name: "Max",
      last_name: "Muster",
      birthday: "01.01.2000"
    }
  }

  describe "validations" do
    it "validates presence of each required attr" do
      expect(form).not_to be_valid
      required_attrs.keys.each do |attr|
        expect(form.errors.attribute_names).to include(attr)
      end
    end
  end
end
