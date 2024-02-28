# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Person::Household do

  let(:user) { Person.first }

  def build_household(person, other)
    Person::Household.new(person, Ability.new(people(:admin)), other, people(:admin))
  end

  def create_person(age, beitragskategorie: :familie, managers: [], **attrs)
    person = Fabricate(:person, **attrs.reverse_merge(
      birthday: age.years.ago,
      town: 'Supertown',
      primary_group: groups(:bluemlisalp_mitglieder)
    ))

    managers.each { |manager| PeopleManager.create!(manager: manager, managed: person) }

    Fabricate(
      Group::SektionsMitglieder::Mitglied.name.to_sym,
      person: person,
      group: groups(:bluemlisalp_mitglieder),
      beitragskategorie: beitragskategorie
    )

    person
  end

  context '#next_key' do
    it 'increments sequence and returns new key' do
      household = Person::Household.new(nil, nil, nil, nil)

      old_value = Sequence.current_value(Person::Household::HOUSEHOLD_KEY_SEQUENCE)
      expect(household.send(:next_key)).to eq "#{old_value + 1}"
      expect(Sequence.current_value(Person::Household::HOUSEHOLD_KEY_SEQUENCE)).to eq old_value + 1
    end
  end

  context '#assign' do
    let(:adult) { create_person(25) }
    let(:other_adult) { create_person(25) }
    let(:child) { create_person(10) }
    let(:other_child) { create_person(10) }

    context 'basic functionality from core' do
      it 'adds person to household' do
        p1 = create_person(25)
        p2 = create_person(25)

        p1.town = 'Greattown'

        household = build_household(p1, p2).tap(&:assign)

        expect(p1.household_people_ids).to eq [p2.id]
        expect(household).to be_address_changed
        expect(household).to be_people_changed
      end
    end

    context 'with adult person' do
      it 'adds child to people_manageds' do
        build_household(adult, child).assign

        expect(adult.people_manageds).to have(1).item
        expect(adult.people_manageds.first.managed).to eq child
      end

      it 'does not add child to people_managers' do
        build_household(adult, child).assign

        expect(adult.people_managers).to be_empty
      end

      it 'does not add adult to people_manageds' do
        build_household(adult, other_adult).assign

        expect(adult.people_manageds).to be_empty
      end

      it 'does not add adult to people_managers' do
        build_household(adult, other_adult).assign

        expect(adult.people_managers).to be_empty
      end
    end

    context 'with child person' do
      it 'adds adult to people_managers' do
        build_household(child, adult).assign

        expect(child.people_managers).to have(1).item
        expect(child.people_managers.first.manager).to eq adult
      end

      it 'does not add adult to people_manageds' do
        build_household(child, adult).assign

        expect(child.people_manageds).to be_empty
      end

      it 'does not add child to people_managers' do
        build_household(child, other_child).assign

        expect(child.people_managers).to be_empty
      end

      it 'does not add child to people_manageds' do
        build_household(child, other_child).assign

        expect(child.people_manageds).to be_empty
      end
    end
  end

  context '#save' do
    it 'persists managers' do
      p1 = create_person(25)
      p2 = create_person(10)

      p1.people_manageds.build(managed: p2)
      household = build_household(p1, p2)

      expect { household.save }.to change { PeopleManager.count }.by(1)
      people_manager = PeopleManager.last
      expect(people_manager.manager).to eq p1
      expect(people_manager.managed).to eq p2
    end

    it 'persists manageds' do
      p1 = create_person(25)
      p2 = create_person(10)

      p2.people_managers.build(manager: p1)
      household = build_household(p2, p1)

      expect { household.save }.to change { PeopleManager.count }.by(1)
      people_manager = PeopleManager.last
      expect(people_manager.manager).to eq p1
      expect(people_manager.managed).to eq p2
    end
  end

  context '#remove' do
    context 'basic functionality from core' do
      it 'dissolves household of two' do
        p1 = create_person(25, household_key: 'household-of-two')
        p2 = create_person(25, household_key: 'household-of-two')

        build_household(p1, p2).remove

        expect(p1.reload.household_key).to be_nil
        expect(p2.reload.household_key).to be_nil
      end

      it 'removes person from household' do
        p1 = create_person(25, household_key: 'household-of-many')
        p2 = create_person(25, household_key: 'household-of-many')
        p3 = create_person(25, household_key: 'household-of-many', beitragskategorie: :jugend)

        build_household(p1, p2).remove

        expect(p1.reload.household_key).to be_nil
        expect(p2.reload.household_key).to eq 'household-of-many'
        expect(p3.reload.household_key).to eq 'household-of-many'
      end
    end

    context 'people_managers' do
      let!(:parent) { create_person(25) }
      let!(:child) { create_person(10, managers: [parent]) }

      it 'get removed from manager' do
        expect { build_household(parent, child).remove }.to change { PeopleManager.count }.by(-1)
        expect(parent.reload.manageds).to be_empty
      end

      it 'get removed from managed' do
        expect { build_household(child, parent).remove }.to change { PeopleManager.count }.by(-1)
        expect(child.reload.managers).to be_empty
      end
    end
  end

end
