# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe GroupAbility do
  describe "export_mitglieder" do
    it "as admin it is permitted" do
      expect(Ability.new(people(:admin))).to be_able_to(:export_mitglieder, groups(:bluemlisalp))
    end

    it "as mitglied it is denied" do
      expect(Ability.new(people(:mitglied))).not_to be_able_to(:export_mitglieder,
        groups(:bluemlisalp))
    end
  end

  describe "create_yearly_membership_invoice" do
    it "as admin it is permitted" do
      expect(Ability.new(people(:admin))).to be_able_to(:create_yearly_membership_invoice, groups(:bluemlisalp))
    end

    it "as mitglied it is denied" do
      expect(Ability.new(people(:mitglied))).not_to be_able_to(:create_yearly_membership_invoice,
        groups(:bluemlisalp))
    end
  end

  describe "download_statistics" do
    let(:person) { people(:roleless) }

    def create_role_with_permission(permission)
      stub_const "TestRole", Class.new(::Role)
      TestRole.permissions = Array(permission)
      TestRole.new(person:, group: groups(:bluemlisalp_funktionaere)).save(validate: false)
    end

    it "without permissions denies download_statistics on any layer" do
      create_role_with_permission(nil)
      ability = Ability.new(person)
      expect(ability.user_context.all_permissions).to be_empty
      expect(ability).not_to be_able_to(:download_statistics, groups(:bluemlisalp))
      expect(ability).not_to be_able_to(:download_statistics, groups(:root))
      expect(ability).not_to be_able_to(:download_statistics, groups(:bluemlisalp_ortsgruppe_ausserberg))
    end

    [:layer_read, :layer_and_below_read, :download_member_statistics].each do |permission|
      context "permission #{permission}" do
        before { create_role_with_permission(permission) }

        it "allows download_statistics on same layer" do
          expect(Ability.new(person)).to be_able_to(:download_statistics, groups(:bluemlisalp))
        end

        it "denies download_statistics on higher layer" do
          expect(Ability.new(person)).not_to be_able_to(:download_statistics, groups(:root))
        end
      end
    end

    [:layer_read, :download_member_statistics].each do |permission|
      it "permission #{permission} denies download_statistics on lower layer" do
        create_role_with_permission(permission)
        expect(Ability.new(person)).not_to be_able_to(:download_statistics, groups(:bluemlisalp_ortsgruppe_ausserberg))
      end
    end

    [:layer_and_below_read].each do |permission|
      it "permission #{permission} allows download_statistics on lower layer" do
        create_role_with_permission(permission)
        expect(Ability.new(person)).to be_able_to(:download_statistics, groups(:bluemlisalp_ortsgruppe_ausserberg))
      end
    end
  end
end
