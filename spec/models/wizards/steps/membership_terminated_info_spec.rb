# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::MembershipTerminatedInfo do
  let(:wizard) { nil } # no wizard needed

  subject(:step) { described_class.new(wizard) }

  describe "validations" do
    it { is_expected.not_to be_valid }
  end

  describe "#termination_date" do
    before do
      stub_const("Wizard", Class.new(Wizards::Base))
      Wizard.steps = [described_class]
    end

    let(:wizard) { Wizard.new(current_step: 0) }
    let(:role) do
      Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
        group: groups(:bluemlisalp_mitglieder))
    end

    before do
      allow(wizard).to receive(:person).and_return(role.person)
    end

    it "returns the termination date of the person" do
      expect(subject.termination_date).to eq(role.end_on)
    end
  end
end
