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
end
