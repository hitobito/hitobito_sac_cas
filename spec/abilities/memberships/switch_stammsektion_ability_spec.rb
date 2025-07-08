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

  def build_wizard(person) = wizard_class.new(person:)

  describe "Wizards::Memberships::SwitchStammsektion" do
    let(:wizard_class) { Wizards::Memberships::SwitchStammsektion }

    context "as backoffice" do
      let(:role) { build_role(Group::Geschaeftsstelle::Admin, :geschaeftsstelle) }

      it "may switch" do
        expect(ability).to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not switch if member not active" do
        people(:mitglied).sac_membership.stammsektion_role.destroy!
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may switch if already terminated" do
        mitglied.sac_membership.stammsektion_role.update_column(:terminated, true)
        expect(ability).to be_able_to(:create, build_wizard(mitglied))
      end
    end

    context "as mitglied" do
      let(:role) { build_role(Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder) }

      it "may not switch for self" do
        expect(ability).not_to be_able_to(:create, build_wizard(role.person))
      end

      it "may not switch for others" do
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not switch for self if already terminated" do
        role.update_column(:terminated, true)
        expect(ability).not_to be_able_to(:create, build_wizard(role.person))
      end
    end

    context "as schreibrecht role" do
      let(:role) { build_role(Group::SektionsMitglieder::Schreibrecht, :bluemlisalp_mitglieder) }

      it "may not switch" do
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not switch if member not active" do
        people(:mitglied).sac_membership.stammsektion_role.destroy!
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not switch if already terminated" do
        mitglied.sac_membership.stammsektion_role.update_column(:terminated, true)
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end
    end
  end

  describe "Wizards::Memberships::SwapStammZusatzsektion" do
    let(:wizard_class) { Wizards::Memberships::SwapStammZusatzsektion }

    context "as backoffice" do
      let(:role) { build_role(Group::Geschaeftsstelle::Admin, :geschaeftsstelle) }

      it "may swap" do
        expect(ability).to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not swap if member not active" do
        people(:mitglied).sac_membership.stammsektion_role.destroy!
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not swap if member has no zusatzsektion" do
        people(:mitglied).sac_membership.zusatzsektion_roles.each(&:destroy!)
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may swap if already terminated" do
        mitglied.sac_membership.stammsektion_role.update_column(:terminated, true)
        expect(ability).to be_able_to(:create, build_wizard(mitglied))
      end

      context "family" do
        it "may swap on main person" do
          expect(ability).to be_able_to(:create, build_wizard(people(:familienmitglied)))
        end

        it "may not swap on other person" do
          expect(ability).not_to be_able_to(:create, build_wizard(people(:familienmitglied2)))
        end
      end
    end

    context "as mitglied" do
      let(:role) { build_role(Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder) }

      it "may not swap for self" do
        expect(ability).not_to be_able_to(:create, build_wizard(role.person))
      end

      it "may not swap for others" do
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not swap for self if already terminated" do
        role.update_column(:terminated, true)
        expect(ability).not_to be_able_to(:create, build_wizard(role.person))
      end
    end

    context "as schreibrecht role" do
      let(:role) { build_role(Group::SektionsMitglieder::Schreibrecht, :bluemlisalp_mitglieder) }

      it "may not swap" do
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not swap if member not active" do
        people(:mitglied).sac_membership.stammsektion_role.destroy!
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end

      it "may not swap if already terminated" do
        mitglied.sac_membership.stammsektion_role.update_column(:terminated, true)
        expect(ability).not_to be_able_to(:create, build_wizard(mitglied))
      end
    end
  end
end
