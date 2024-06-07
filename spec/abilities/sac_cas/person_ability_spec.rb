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
    let(:person) { mitglied }
    let!(:household_person1) { Fabricate(:person) }
    let!(:household_person2) { Fabricate(:person) }

    context 'when person has no household people' do
      it 'cannot set family main person' do
        expect(ability).not_to be_able_to(:set_sac_family_main_person, person)
      end
    end

    context 'when person is not an adult' do
      before do
        person.update!(birthday: 17.years.ago)
      end

      it 'cannot set family main person' do
        expect(ability).not_to be_able_to(:set_sac_family_main_person, person)
      end
    end

    context 'when person is an adult and all household people are writable' do
      before do
        person.update!(birthday: 44.years.ago)
        create_household([household_person1, household_person2])


        allow(ability).to receive(:can?).with(:update, household_person1).and_return(true)
        allow(ability).to receive(:can?).with(:update, household_person2).and_return(true)
      end

      it 'can set family main person' do
        expect(ability).to be_able_to(:set_sac_family_main_person, person)
      end
    end

    context 'when person is an adult and not all household people are writable' do

      before do
        person.update!(birthday: 44.years.ago)
        create_household([household_person1, household_person2])

        allow(ability).to receive(:can?).with(:update, household_person1).and_return(true)
        allow(ability).to receive(:can?).with(:update, household_person2).and_return(false)
      end

      it 'cannot set family main person' do
        expect(ability).not_to be_able_to(:set_sac_family_main_person, person)
      end
    end
  end

  private

  def create_household(people_in_household_with_person)
    household = Household.new(person)
    people_in_household_with_person.each do |person|
      household.add(person)
    end
    household.save
    household.reload
  end
end
