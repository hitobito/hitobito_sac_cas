# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe VariousAbility do

  def build_role(type)
    Fabricate.build(type.sti_name, group: group).tap do |r|
      r.person.roles = [r]
    end
  end

  let(:group) { groups(:geschaeftsstelle) }
  subject(:ability) { Ability.new(build_role(role).person) }

  context 'without admin permission' do
    let(:role) { Group::Geschaeftsstelle::Mitarbeiter }

    it 'may not view nor manage CostCenter records' do
      expect(ability).not_to be_able_to(:index, CostCenter)
      expect(ability).not_to be_able_to(:manage, CostCenter.new)
    end
  end

  context 'with admin permission' do
    let(:role) { Group::Geschaeftsstelle::Admin }

    it 'may not view nor manage CostCenter records' do
      expect(ability).to be_able_to(:index, CostCenter)
      expect(ability).to be_able_to(:manage, CostCenter.new)
    end
  end
end
