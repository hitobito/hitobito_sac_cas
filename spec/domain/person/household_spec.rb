# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Person::Household do

  let(:user) { people(:root) }

  def build_household(person, other, **opts)
    Person::Household.new(person, Ability.new(user), other, people(:admin), **opts)
  end

  def create_person(age, beitragskategorie: :familie, managers: [], **attrs)
    person = Fabricate(:person, **attrs.reverse_merge(
      birthday: age.years.ago,
      town: 'Supertown',
      primary_group: groups(:bluemlisalp_mitglieder)
    ))

    Array.wrap(managers).each { |manager| PeopleManager.create!(manager: manager, managed: person) }

    if beitragskategorie
      Fabricate(
        Group::SektionsMitglieder::Mitglied.name.to_sym,
        person: person,
        group: groups(:bluemlisalp_mitglieder),
        beitragskategorie: beitragskategorie
      )
    end

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
  end

  context "#valid?" do
    it 'is false if existing person and new person both have family memberships' do
      p1 = create_person(25, beitragskategorie: :familie)
      p2 = create_person(25, beitragskategorie: :familie)

      expect(build_household(p1, p2)).not_to be_valid
    end

    it 'is true if existing person has family membership and new person does not' do
      p1 = create_person(25, beitragskategorie: :familie)
      p2 = create_person(25, beitragskategorie: :einzel)
      expect(build_household(p1, p2)).to be_valid

      p3 = create_person(25, beitragskategorie: :familie)
      p4 = create_person(25, beitragskategorie: nil)
      expect(build_household(p3, p4)).to be_valid
    end

    it 'is true if existing person does not have family membership and new person does' do
      p1 = create_person(25, beitragskategorie: :einzel)
      p2 = create_person(25, beitragskategorie: :familie)
      expect(build_household(p1, p2)).to be_valid

      p3 = create_person(25, beitragskategorie: nil)
      p4 = create_person(25, beitragskategorie: :familie)
      expect(build_household(p3, p4)).to be_valid
    end

    it 'is true if neither existing person nor new person have family memberships' do
      p1 = create_person(25, beitragskategorie: :einzel)
      p2 = create_person(25, beitragskategorie: :einzel)
      expect(build_household(p1, p2)).to be_valid

      p3 = create_person(25, beitragskategorie: nil)
      p4 = create_person(25, beitragskategorie: nil)
      expect(build_household(p3, p4)).to be_valid
    end
  end

  context '#save' do
    let(:adult) { create_person(25, beitragskategorie: nil) }
    let(:child) { create_person(10, beitragskategorie: nil) }
    let(:other_adult) { create_person(25, beitragskategorie: nil) }
    let(:other_child) { create_person(10, beitragskategorie: nil) }

    context 'with adult person' do
      it 'adds child to manageds' do
        household = build_household(adult, child).tap(&:assign)

        expect { household.send(:save) }.to change { PeopleManager.count }.by(1)
        expect(adult.manageds).to contain_exactly(child)
      end

      it 'does not create PeopleManager for other adult' do
        household = build_household(adult, other_adult).tap(&:assign)

        expect { household.send(:save) }.not_to change { PeopleManager.count }
      end
    end

    context 'with child person' do
      it 'adds adult to managers' do
        household = build_household(child, adult).tap(&:assign)

        expect { household.send(:save) }.to change { PeopleManager.count }.by(1)
        expect(child.managers).to contain_exactly(adult)
      end

      it 'does not create PeopleManager for other child' do
        household = build_household(child, other_child).tap(&:assign)

        expect { household.send(:save) }.not_to change { PeopleManager.count }
      end
    end

    context 'sac_family' do
      it 'calls sac_family.update!' do
        household = build_household(adult, child).tap(&:assign)

        expect(household).to be_maintain_sac_family
        expect(adult.sac_family).to receive(:update!)

        household.send(:save)
      end

      it 'does not call sac_family.update! with maintain_sac_family=false' do
        household = build_household(adult, child, maintain_sac_family: false).tap(&:assign)

        expect(household).not_to be_maintain_sac_family
        expect(adult.sac_family).not_to receive(:update!)

        household.send(:save)
      end
    end

    it 'raises if new family member already has family membership' do
      p1 = create_person(25, beitragskategorie: :familie)
      p2 = create_person(10, beitragskategorie: :familie)

      household = build_household(p1, p2)

      expect { household.send(:save) }.to raise_error('invalid')
    end
  end

  context '#remove' do
    context 'basic functionality from core' do
      it 'dissolves household of two' do
        p1 = create_person(25, household_key: 'household-of-two')
        p2 = create_person(25, household_key: 'household-of-two')

        build_household(p1, p2).send(:remove)

        expect(p1.reload.household_key).to be_nil
        expect(p2.reload.household_key).to be_nil
      end

      it 'removes person from household' do
        p1 = create_person(25, household_key: 'household-of-many')
        p2 = create_person(25, household_key: 'household-of-many')
        p3 = create_person(25, household_key: 'household-of-many', beitragskategorie: :jugend)

        build_household(p1, p2).send(:remove)

        expect(p1.reload.household_key).to be_nil
        expect(p2.reload.household_key).to eq 'household-of-many'
        expect(p3.reload.household_key).to eq 'household-of-many'
      end
    end

    context 'people_managers' do
      let!(:parent) { create_person(25) }
      let!(:child) { create_person(10, managers: parent) }

      it 'get removed from manager' do
        expect { build_household(parent, child).send(:remove) }.to change { PeopleManager.count }.by(-1)
        expect(parent.reload.manageds).to be_empty
      end

      it 'get removed from managed' do
        expect { build_household(child, parent).send(:remove) }.to change { PeopleManager.count }.by(-1)
        expect(child.reload.managers).to be_empty
      end
    end
  end

end
