# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe PersonAbility do

  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:funktionaere) { groups(:bluemlisalp_funktionaere) }
  subject(:ability) { Ability.new(person) }

  describe 'primary_group' do
    context 'mitglied updating himself' do
      let(:person) { people(:mitglied) }

      it 'is not permitted if primary group is a preferred group' do
        expect(ability).not_to be_able_to(:primary_group, mitglied)
      end

      it 'is not permitted if primary group is a non preferred group' do
        Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: mitglied)
        mitglied.update!(primary_group: funktionaere)
        expect(ability).to be_able_to(:primary_group, mitglied)
      end

      it 'is not permitted for other person' do
        expect(ability).not_to be_able_to(:primary_group, mitglied)
      end
    end

    context 'admin updating mitglied' do
      let(:person) { admin }

      it 'is permitted for other' do
        expect(ability).to be_able_to(:primary_group, mitglied)
      end
    end
  end
end
