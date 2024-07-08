# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::ChooseMembership do
  let(:wizard) { Wizards::Base.new(current_step: 0) }

  subject(:step) { described_class.new(wizard) }

  describe "validations" do
    let(:error) { steps.errors[:reigster_as] }

    it "validates presence of group id" do
      step.register_as = nil
      expect(step).not_to be_valid
      expect(step.errors[:register_as]).to match_array [
        "muss ausgefüllt werden",
        "ist kein gültiger Wert"
      ]
    end

    it "validates register_as value" do
      step.register_as = :tbd
      expect(step).not_to be_valid
      expect(step.errors[:register_as]).to eq ["ist kein gültiger Wert"]
    end

    it "accepts family as register_as value" do
      step.register_as = :family
      expect(step).to be_valid
    end

    it "accepts myself as register_as value" do
      step.register_as = :myself
      expect(step).to be_valid
    end
  end
end
