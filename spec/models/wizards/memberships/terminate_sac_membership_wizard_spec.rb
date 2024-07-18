# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Memberships::TerminateSacMembershipWizard do
  let(:matterhorn) { groups(:matterhorn) }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:backoffice) { false }
  let(:params) { {} }
  let(:role) { person.roles.find_by!(type: "Group::SektionsMitglieder::Mitglied") }
  let(:person) { people(:mitglied) }
  let(:current_step) { 0 }
  let(:wizard) do
    described_class.new(current_step:, backoffice:, person:, **params)
  end

  context "with terminated primary role" do
    it "only has MembershipTerminatedInfo step" do
      role.update_column(:terminated, true)
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::MembershipTerminatedInfo)
      expect(wizard.step_at(1)).to be_nil
    end
  end

  def expect_backoffice_steps
    expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::TerminationChooseDate)
    expect(wizard.step_at(1)).to be_kind_of(Wizards::Steps::Termination::Summary)
    expect(wizard.step_at(2)).to be_nil
  end

  context "If termination is by section only" do
    before do
      allow(wizard).to receive(:role).and_return(role)
      allow(role.layer_group).to receive(:mitglied_termination_by_section_only).and_return(true)
    end

    it "only has TerminationNoSelfService step" do
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::TerminationNoSelfService)
      expect(wizard.step_at(1)).to be_nil
    end

    context "when operator is backoffice" do
      let(:backoffice) { true }

      it "includes the backoffice steps" do
        expect_backoffice_steps
      end
    end
  end

  context "for main person inside a household" do
    let(:person) { people(:familienmitglied) }

    it "only has the Summary step" do
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::Termination::Summary)
      expect(wizard.step_at(1)).to be_nil
      expect(wizard).not_to be_valid
    end
  end

  context "when operator is backoffice" do
    let(:backoffice) { true }

    it "includes the backoffice steps" do
      expect_backoffice_steps
    end
  end

  context "for person inside a household" do
    let(:person) { people(:familienmitglied2) }

    it "only has the AskFamilyMainPerson step" do
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::AskFamilyMainPerson)
      expect(wizard.step_at(1)).to be_nil
    end

    it "has family_membership" do
      expect(wizard.family_membership?).to be true
    end
  end
end
