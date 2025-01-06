# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
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

  let(:group) { groups(:geschaeftsstelle) }

  def build_wizard(person)
    Wizards::Memberships::SwitchStammsektion.new(current_step: 0, person: people(person))
  end

  subject(:ability) { Ability.new(role.person) }

  context "as mitarbeiter" do
    let(:role) { build_role(Group::Geschaeftsstelle::Mitarbeiter, :geschaeftsstelle) }

    it "may create switch stammsektion wizard" do
      expect(ability).to be_able_to(:create, build_wizard(:mitglied))
    end

    it "may not create switch stammsektion wizard for mitglied with data quality issues" do
      people(:mitglied).update_column(:birthday, nil)
      People::DataQualityChecker.new(people(:mitglied)).check_data_quality
      expect(ability).not_to be_able_to(:create, build_wizard(:mitglied))
    end
  end

  context "as mitglied" do
    let(:role) { roles(:mitglied) }

    it "may not create switch stammsektion wizard for herself" do
      expect(ability).not_to be_able_to(:create, build_wizard(:mitglied))
    end
  end
end
