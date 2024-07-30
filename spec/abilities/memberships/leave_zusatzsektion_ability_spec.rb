# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::LeaveZusatzsektionAbility do
  def build_role(type, group)
    Fabricate(type.sti_name, group: groups(group)).tap do |r|
      r.person.roles = [r]
    end
  end

  let(:sektion) { groups(:bluemlisalp) }
  let(:group) { groups(:geschaeftsstelle) }

  def build_leave(key)
    role = roles(key)
    Wizards::Memberships::LeaveZusatzsektion.new(current_step: 0, person: role.person, role:)
  end

  subject(:ability) { Ability.new(role.person) }

  context "as admin" do
    let(:role) { build_role(Group::Geschaeftsstelle::Admin, :geschaeftsstelle) }

    it "may create leave for mitglied" do
      expect(ability).to be_able_to(:create, build_leave(:mitglied))
    end

    it "may not create leave if membership is no longer active" do
      roles(:mitglied).update(deleted_at: 1.day.ago)
      expect(ability).not_to be_able_to(:create, build_leave(:mitglied))
    end

    it "may not create leave for admin as admin has no membership" do
      expect(ability).not_to be_able_to(:create, build_leave(:admin))
    end
  end

  context "as mitarbeiter" do
    let(:role) { build_role(Group::Geschaeftsstelle::Mitarbeiter, :geschaeftsstelle) }

    it "may create leave for mitglied" do
      expect(ability).to be_able_to(:create, build_leave(:mitglied))
    end

    it "may not create leave if membership is no longer active" do
      roles(:mitglied).update(deleted_at: 1.day.ago)
      expect(ability).not_to be_able_to(:create, build_leave(:mitglied))
    end

    it "may not create leave for admin as admin has no membership" do
      expect(ability).not_to be_able_to(:create, build_leave(:admin))
    end
  end

  context "as person with active membership" do
    let(:role) { roles(:mitglied) }

    it "may create leave for herself" do
      expect(ability).to be_able_to(:create, build_leave(:mitglied))
    end

    it "may not create leave for other person" do
      expect(ability).not_to be_able_to(:create, build_leave(:familienmitglied))
    end

    it "may not create leave for herself if membership is no longer active" do
      roles(:mitglied).update_columns(deleted_at: Time.zone.now)
      expect(ability).not_to be_able_to(:create, build_leave(:mitglied))
    end
  end
end
