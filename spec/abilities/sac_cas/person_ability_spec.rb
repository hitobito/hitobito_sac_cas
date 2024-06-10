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

      it 'is permitted' do
        expect(ability).to be_able_to(:primary_group, mitglied)
      end
    end

    context 'admin updating mitglied' do
      let(:person) { admin }

      it 'is permitted' do
        expect(ability).to be_able_to(:primary_group, mitglied)
      end
    end
  end

  describe 'create_households' do
    [Group::Geschaeftsstelle::Mitarbeiter, Group::Geschaeftsstelle::Admin].each do |role_type|
      context role_type do
        let(:person) { Fabricate(role_type.sti_name, group: groups(:geschaeftsstelle)).person }

        it 'is permitted' do
          expect(ability).to be_able_to(:create_households, mitglied)
        end
      end
    end

    [Group::SektionsFunktionaere::Mitgliederverwaltung, Group::SektionsFunktionaere::Administration].each do |role_type|
      context role_type do
        let(:person) { Fabricate(role_type.sti_name, group: groups(:bluemlisalp_funktionaere)).person }

        it 'is not permitted' do
          expect(ability).not_to be_able_to(:create_households, mitglied)
        end
      end
    end
  end

  describe 'household' do
    let(:admin_ability) { Ability.new(admin) }
    let(:mitglied_ability) { Ability.new(mitglied) }
    let(:familienmitglied2) { people(:familienmitglied2) }
    let(:familienmitglied2_ability) { Ability.new(familienmitglied2) }

    let(:mitgliederverwaltung_sektion) do
      Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
                group: groups(:bluemlisalp_funktionaere)).person
    end
    let(:mitgliederverwaltung_sektion_ability) { Ability.new(mitgliederverwaltung_sektion) }

    let(:child) { people(:familienmitglied_kind) }

    context 'sac_family_main_person' do
      it 'can be set as admin' do
        expect(admin_ability).to be_able_to(:set_sac_family_main_person, familienmitglied2)
      end

      it 'cannot be set as mitglied' do
        expect(mitglied_ability).not_to be_able_to(:set_sac_family_main_person, familienmitglied2)
      end

      it 'cannot be set as yourself' do
        expect(familienmitglied2_ability).not_to be_able_to(:set_sac_family_main_person, familienmitglied2)
      end

      it 'can be set as mitgliederverwaltung_sektion' do
        expect(mitgliederverwaltung_sektion_ability).to be_able_to(:set_sac_family_main_person, familienmitglied2)
      end

      it 'cannot set when person is not an adult' do
        expect(mitgliederverwaltung_sektion_ability).not_to be_able_to(:set_sac_family_main_person, child)
      end
    end
  end
end
