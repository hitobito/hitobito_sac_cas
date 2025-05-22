#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::ChangeZusatzsektionToFamilyAbility do
  subject(:ability) { Ability.new(role.person) }

  let(:zusatzsektion_role) do
    p = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: groups(:bluemlisalp_mitglieder)).person
    Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, group: groups(:matterhorn_mitglieder), person: p)
  end

  context "as backoffice" do
    let(:role) { Fabricate(Group::Geschaeftsstelle::Admin.sti_name, group: groups(:geschaeftsstelle)) }

    it "may manage" do
      expect(ability).to be_able_to(:manage, Memberships::ChangeZusatzsektionToFamily.new(zusatzsektion_role))
    end
  end

  context "as mitglied" do
    let(:role) { Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: groups(:bluemlisalp_mitglieder)) }

    it "may not manage" do
      expect(ability).to_not be_able_to(:manage, Memberships::ChangeZusatzsektionToFamily.new(zusatzsektion_role))
    end
  end
end
