# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::People::Memberships do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:current_user) { person }
  let(:stammsektion_role) { person.sac_membership.stammsektion_role }

  let(:dropdown) { described_class.new(self, person, group) }
  let(:ability) { instance_double(Ability) }

  subject { Capybara.string(dropdown.to_s) }

  before do
    allow(self).to receive(:current_ability).and_return(ability)
    allow(self).to receive(:current_user).and_return(current_user)
  end

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  def stub_can_create(wizard_class, value)
    allow(ability).to receive(:can?).with(:create,
      kind_of(wizard_class)).and_return(value)
  end

  context "JoinZusatzsektion" do
    before do
      stub_can_create(Wizards::Memberships::SwitchStammsektion, false)
      expect(ability).to receive(:can?).with(:create, Memberships::UndoTermination).and_return(false)
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(false)
    end

    it "is empty when person is not permitted" do
      stub_can_create(Wizards::Memberships::JoinZusatzsektion, false)
      expect(dropdown.to_s).to be_blank
    end

    it "is contains links if person is permitted" do
      stub_can_create(Wizards::Memberships::JoinZusatzsektion, true)
      expect(menu).to have_link "Zusatzsektion beantragen"
    end
  end

  context "SwitchStammsektion" do
    before do
      stub_can_create(Wizards::Memberships::JoinZusatzsektion, false)
      expect(ability).to receive(:can?).with(:create, Memberships::UndoTermination).and_return(false)
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(false)
    end

    it "is empty when person is not permitted" do
      stub_can_create(Wizards::Memberships::SwitchStammsektion, false)
      expect(dropdown.to_s).to be_blank
    end

    it "is contains links if person is permitted" do
      stub_can_create(Wizards::Memberships::SwitchStammsektion, true)
      expect(menu).to have_link "Sektionswechsel beantragen"
    end
  end

  context "SwapStammZusatzsektion" do
    before do
      stub_can_create(Wizards::Memberships::JoinZusatzsektion, false)
      stub_can_create(Wizards::Memberships::SwitchStammsektion, false)
      expect(ability).to receive(:can?).with(:create, Memberships::UndoTermination).and_return(false)
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(false)
    end

    it "is empty when person is not permitted" do
      stub_can_create(Wizards::Memberships::SwapStammZusatzsektion, false)
      expect(dropdown.to_s).to be_blank
    end

    it "is contains links if person is permitted" do
      stub_can_create(Wizards::Memberships::SwapStammZusatzsektion, true)
      expect(menu).to have_link "Stamm- und Zusatzsektion tauschen"
    end
  end

  context "TerminateSacMembershipWizard" do
    before do
      stub_can_create(Wizards::Memberships::JoinZusatzsektion, false)
      stub_can_create(Wizards::Memberships::SwitchStammsektion, false)
      expect(ability).to receive(:can?).with(:create, Memberships::UndoTermination).and_return(false)
    end

    it "is empty when person is not permitted" do
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(false)
      expect(dropdown.to_s).to be_blank
    end

    it "is contains link if person is permitted and sektion allows" do
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(true)
      stammsektion_role.layer_group.mitglied_termination_by_section_only = false
      stammsektion_role.layer_group.save!
      expect(menu).to have_link "SAC-Mitgliedschaft beenden"
    end

    it "is hides link if person is permitted for self but sektion denies" do
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(true)
      stammsektion_role.layer_group.mitglied_termination_by_section_only = true
      stammsektion_role.layer_group.save!
      expect(dropdown.to_s).to be_blank
    end

    it "is contains link if person is permitted for other even if sektion disallows" do
      allow(self).to receive(:current_user).and_return(people(:admin))
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(true)
      stammsektion_role.layer_group.mitglied_termination_by_section_only = true
      stammsektion_role.layer_group.save!
      expect(menu).to have_link "SAC-Mitgliedschaft beenden"
    end
  end

  context "UndoTermination" do
    before do
      stub_can_create(Wizards::Memberships::JoinZusatzsektion, false)
      stub_can_create(Wizards::Memberships::SwitchStammsektion, true)
      expect(ability).to receive(:can?).with(:terminate, stammsektion_role).and_return(false)
    end

    it "does not contain link if person is not permitted" do
      person.sac_membership.stammsektion_role.update_column(:terminated, true)
      expect(ability).to receive(:can?).with(:create,
        Memberships::UndoTermination).and_return(false)
      expect(menu).to have_no_link "SAC-Mitgliedschaft reaktivieren"
    end

    it "does not contain link if membership stammsektion role is not terminated" do
      expect(ability).to receive(:can?).with(:create,
        Memberships::UndoTermination).and_return(false)
      expect(menu).to have_no_link "SAC-Mitgliedschaft reaktivieren"
    end

    it "is contains link if person is permitted" do
      person.sac_membership.stammsektion_role.update_column(:terminated, true)
      expect(ability).to receive(:can?).with(:create, Memberships::UndoTermination).and_return(true)
      expect(menu).to have_link "SAC-Mitgliedschaft reaktivieren"
    end
  end
end
