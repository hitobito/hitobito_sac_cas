#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::SwitchStammsektionAbility do
  def build_role(type, group)
    Fabricate(type.sti_name, group: groups(group)).tap do |r|
      r.person.roles = [r]
    end
  end

  subject(:ability) { Ability.new(role.person) }

  let(:mitglied) { people(:mitglied) }

  context "as backoffice" do
    let(:role) { build_role(Group::Geschaeftsstelle::Admin, :geschaeftsstelle) }

    it "may switch" do
      expect(ability).to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: mitglied))
    end

    it "may not switch if member not active" do
      people(:mitglied).sac_membership.stammsektion_role.destroy!
      expect(ability).not_to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: mitglied))
    end

    it "may switch if already terminated" do
      mitglied.sac_membership.stammsektion_role.update_column(:terminated, true)
      expect(ability).to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: mitglied))
    end
  end

  context "as mitglied" do
    let(:role) { build_role(Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder) }

    it "may not switch for self" do
      expect(ability).not_to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: role.person))
    end

    it "may not switch for others" do
      expect(ability).not_to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: mitglied))
    end

    it "may not switch for self if already terminated" do
      role.update_column(:terminated, true)
      expect(ability).not_to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: role.person))
    end
  end

  context "as schreibrecht role" do
    let(:role) { build_role(Group::SektionsMitglieder::Schreibrecht, :bluemlisalp_mitglieder) }

    it "may not switch" do
      expect(ability).not_to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: mitglied))
    end

    it "may not switch if member not active" do
      people(:mitglied).sac_membership.stammsektion_role.destroy!
      expect(ability).not_to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: mitglied))
    end

    it "may not switch if already terminated" do
      mitglied.sac_membership.stammsektion_role.update_column(:terminated, true)
      expect(ability).not_to be_able_to(:create, Wizards::Memberships::SwitchStammsektion.new(person: mitglied))
    end
  end
end
