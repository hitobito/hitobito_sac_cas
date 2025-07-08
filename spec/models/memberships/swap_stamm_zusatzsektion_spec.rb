# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::SwapStammZusatzsektion do
  before { travel_to(now) }

  let(:now) { Time.zone.local(2024, 6, 19, 15, 33) }

  let(:group) { groups(:matterhorn) }
  let(:matterhorn) { groups(:matterhorn) }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }

  subject(:switch) { described_class.new(matterhorn, person) }

  describe "einzeln einzel" do
    let(:person) { people(:mitglied) }

    it "can make the switch" do
      expect do
        expect(switch.save!).to be_truthy
      end.not_to change { person.roles.count }
      expect(person.reload.primary_group).to eq matterhorn_mitglieder
      expect(person.sac_membership.stammsektion_role.layer_group).to eq matterhorn
      expect(person.sac_membership.zusatzsektion_roles).to have(1).item
      expect(person.sac_membership.zusatzsektion_roles.first.layer_group).to eq bluemlisalp
    end
  end

  describe "family" do
    let(:person) { people(:familienmitglied) }
    let(:family_member) { people(:familienmitglied2) }

    it "can make the switch" do
      expect do
        expect(switch.save!).to be_truthy
      end.not_to change { person.roles.count }
      expect(person.reload.primary_group).to eq matterhorn_mitglieder
      expect(person.sac_membership.stammsektion_role.layer_group).to eq matterhorn
      expect(person.sac_membership.zusatzsektion_roles).to have(1).item
      expect(person.sac_membership.zusatzsektion_roles.first.layer_group).to eq bluemlisalp

      expect(family_member.reload.primary_group).to eq matterhorn_mitglieder
      expect(family_member.sac_membership.stammsektion_role.layer_group).to eq matterhorn
      expect(family_member.sac_membership.zusatzsektion_roles).to have(1).item
      expect(family_member.sac_membership.zusatzsektion_roles.first.layer_group).to eq bluemlisalp
    end

    context "when used on other than main family person" do
      let(:person) { people(:familienmitglied2) }
      let(:family_member) { people(:familienmitglied) }

      it "is invalid" do
        expect(switch).not_to be_valid
        expect(switch.errors.full_messages).to eq ["Person muss Hauptperson der Familie sein"]
      end
    end
  end
end
