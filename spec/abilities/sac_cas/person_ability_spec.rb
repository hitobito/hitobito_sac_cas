# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe PersonAbility do

  let(:mitglied) { people(:mitglied) }
  let(:funktionaere) { groups(:bluemlisalp_funktionaere) }


  describe 'primary_group' do
    context 'her own' do
      subject(:ability) { Ability.new(mitglied) }

      it 'is not permitted if primary group is a Group::SektionsMitglieder' do
        expect(ability).not_to be_able_to(:primary_group, mitglied)
      end

      it 'is permitted if primary_group is not a Group::SektionsMitglieder' do
        Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: mitglied)
        mitglied.update!(primary_group: funktionaere)
        expect(ability).to be_able_to(:primary_group, mitglied)
      end

      it 'is not permitted for other person' do
        expect(ability).not_to be_able_to(:primary_group, people(:admin))
      end

    end

    describe 'others' do
      subject(:ability) { Ability.new(people(:admin)) }

      it 'is permitted for other' do
        expect(ability).to be_able_to(:primary_group, mitglied)
      end
    end
  end
end
