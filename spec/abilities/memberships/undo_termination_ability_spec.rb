#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::UndoTerminationAbility do
  def build_role(type, group)
    Fabricate(type.sti_name, group: groups(group)).tap do |r|
      r.person.roles = [r]
    end
  end

  subject(:ability) { Ability.new(role.person) }

  let(:terminated_role) do
    r = build_role(Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder)
    # monkey dance required because directly assigning terminated intentionally raises error
    r.tap { _1.write_attribute(:terminated, true) }.save!
    r
  end

  context "as backoffice" do
    let(:role) { build_role(Group::Geschaeftsstelle::Admin, :geschaeftsstelle) }

    it "may manage" do
      expect(ability).to be_able_to(:manage, Memberships::UndoTermination.new(terminated_role))
    end
  end

  context "as mitglied" do
    let(:role) { build_role(Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder) }

    it "may not manage" do
      expect(ability).to_not be_able_to(:manage, Memberships::UndoTermination.new(terminated_role))
    end
  end
end
