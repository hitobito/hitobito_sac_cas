# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe ExternalTrainingAbility do
  let(:user) { role.person }
  let(:user_group) { role.group }

  let(:external_training) { Fabricate(:external_training, person: person) }
  subject(:ability) { Ability.new(role.person) }

  context 'with layer_and_below_full' do
    let(:role) { Fabricate(Group::Geschaeftsstelle::Mitarbeiter.name.to_sym, group: groups(:geschaeftsstelle)) }

    context 'in same layer' do
      let(:person) { Fabricate(Group::Geschaeftsstelle::MitarbeiterLesend.name.to_sym, group: groups(:geschaeftsstelle)).person }

      it 'can create and destroy' do
        expect(ability).to be_able_to(:create, external_training)
        expect(ability).to be_able_to(:destroy, external_training)
      end
    end

    context 'in layer below' do
      let(:person) { Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym, group: groups(:bluemlisalp_mitglieder)).person }

      it 'can create and destroy in layer below' do
        expect(ability).to be_able_to(:create, external_training)
        expect(ability).to be_able_to(:destroy, external_training)
      end
    end
  end

  context 'with group_full' do
    let(:role) { Fabricate(Group::SektionsTourenkommission::TourenchefSommer.name.to_sym, group: groups(:bluemlisalp_ortsgruppe_ausserberg_tourenkommission)) }

    context 'in same group' do
      let(:person) { Fabricate(Group::SektionsTourenkommission::Tourenleiter.name.to_sym,
                               group: groups(:bluemlisalp_ortsgruppe_ausserberg_tourenkommission),
                               person: Fabricate(:person, qualifications: [Fabricate(:qualification)])).person }
      it 'can create and destroy' do
        is_expected.to be_able_to(:create, external_training)
        is_expected.to be_able_to(:destroy, external_training)
      end
    end
  end
end

