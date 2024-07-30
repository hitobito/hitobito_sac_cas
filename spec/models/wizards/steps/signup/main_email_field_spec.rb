# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::MainEmailField do
  subject(:field) { described_class.new(double("wizard")) }

  describe "validations" do
    it "requires email to be set" do
      expect(field).not_to be_valid
    end

    it "does validate email format" do
      field.email = "foobar"
      expect(field).not_to be_valid
    end

    it "is valid if required attrs are set" do
      field.email = "max.muster@example.com"
      expect(field).to be_valid
    end
  end
end
