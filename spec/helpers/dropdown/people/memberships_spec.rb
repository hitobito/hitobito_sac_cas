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

  let(:dropdown) { described_class.new(self, person, group) }
  let(:ability) { instance_double(Ability) }

  subject { Capybara.string(dropdown.to_s) }

  before do
    allow(self).to receive(:current_ability).and_return(ability)
    allow(self).to receive(:current_user).and_return(current_user)
  end

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  def stub_can_create(wizard_class, value)
    expect(ability).to receive(:can?).with(:create,
      kind_of(wizard_class)).and_return(value)
  end

  context "JoinZusatzsektion" do
    before do
      stub_can_create(Wizards::Memberships::SwitchStammsektion, false)
      stub_can_create(Wizards::Memberships::TerminateSacMembershipWizard, false)
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
      stub_can_create(Wizards::Memberships::TerminateSacMembershipWizard, false)
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

  context "TerminateSacMembershipWizard" do
    before do
      stub_can_create(Wizards::Memberships::JoinZusatzsektion, false)
      stub_can_create(Wizards::Memberships::SwitchStammsektion, false)
    end

    it "is empty when person is not permitted" do
      stub_can_create(Wizards::Memberships::TerminateSacMembershipWizard, false)
      expect(dropdown.to_s).to be_blank
    end

    it "is contains links if person is permitted" do
      stub_can_create(Wizards::Memberships::TerminateSacMembershipWizard, true)
      expect(menu).to have_link "SAC-Mitgliedschaft beenden"
    end
  end
end
