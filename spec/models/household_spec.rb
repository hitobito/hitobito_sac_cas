# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Household do

  let(:person) { Fabricate(:person, birthday: Date.new(2000, 1, 1)) }
  let(:adult) { Fabricate(:person, birthday: Date.new(1999, 10, 5)) }
  let(:child) { Fabricate(:person, birthday: Date.new(2012, 9, 23)) }
  let(:second_child) { Fabricate(:person, birthday: Date.new(2014, 4, 13)) }
  let(:second_adult) { Fabricate(:person, birthday: Date.new(1998, 11, 6)) }

  subject(:household) { Household.new(person) }

  before { travel_to(Date.new(2024, 5, 31)) }

  def add_and_save(*members)
    household.add(person)
    members.each { |member| household.add(member) }
    expect(household.save).to eq true
  end

  def remove_and_save(*members)
    members.each { |member| household.remove(member) }
    expect(household.save).to eq true
  end

  it 'uses sequence for household key' do
    add_and_save(adult)
    expect(Sequence.find_by(current_value: '500001').name).to eq 'person.household_key'
    expect(adult.reload.household_key).to eq '500001'
  end

  describe 'maintaining sac_family' do
    it 'updates sac_family' do
      expect(person.sac_family).to receive(:update!)
      expect(household.save).to eq true
    end

    it 'ignores return value of sac_family#update!' do
      expect(person.sac_family).to receive(:update!).and_return(false)
      expect(household.save).to eq true
    end

    it 'does not update sac_family if told to skip' do
      household = Household.new(person, maintain_sac_family: false)
      expect(person.sac_family).not_to receive(:update!)
      expect(household.save).to eq true
    end
  end

  describe 'people manager relations' do
    context 'adding people' do
      it 'noops when adding adult' do
        expect { add_and_save(adult) }.not_to(change { PeopleManager.count })
      end

      it 'noops when adding two adults' do
        expect { add_and_save(adult, second_adult) }.not_to(change { PeopleManager.count })
      end

      it 'noops if relation exists' do
        person.people_manageds.create!(managed: child)
        expect { add_and_save(child) }.not_to(change { PeopleManager.count })
      end

      it 'creates relation' do
        expect { add_and_save(child) }.to change { PeopleManager.count }.by(1)
        expect(person.manageds).to eq [child]
        expect(child.managers).to eq [person]
      end

      it 'creates only missing relations' do
        person.people_manageds.create!(managed: child)
        expect { add_and_save(child, second_child) }.to change { PeopleManager.count }.by(1)
        expect(person.manageds).to match_array([child, second_child])
        expect(child.managers).to eq [person]
        expect(second_child.managers).to eq [person]
      end

      it 'creates multiple relations for child' do
        person.people_manageds.create!(managed: child)
        expect { add_and_save(child, adult) }.to change { PeopleManager.count }.by(1)
        expect(child.managers).to match_array([person, adult])
      end

      it 'noops and raises if error occurs' do
        expect(PeopleManager).to receive(:create!).once.and_call_original
        expect(PeopleManager).to receive(:create!).and_raise('ouch')
        expect do
          add_and_save(child, second_child)
        end.to raise_error('ouch').and(not_change { PeopleManager.count })
      end
    end

    context 'removing people' do
      it 'removes single relation' do
        add_and_save(adult, child)
        expect { remove_and_save(adult) }.to change { PeopleManager.count }.by(-1)
      end

      it 'removes multiple relations' do
        add_and_save(adult, child, second_child)
        expect { remove_and_save(adult, child) }.to change { PeopleManager.count }.by(-3)
        expect(person.manageds).to eq [second_child]
        expect(second_child.managers).to eq [person]
        expect(adult.reload.manageds).to be_empty
        expect(child.reload.managers).to be_empty
      end
    end

    describe 'destroying household' do
      it 'removes relation' do
        add_and_save(child)
        expect { household.destroy }.to change { PeopleManager.count }.by(-1)
      end

      it 'removes relations' do
        add_and_save(adult, child, second_child)
        expect { household.destroy }.to change { PeopleManager.count }.by(-4)
      end

      it 'noops and raises when error occurs' do
        add_and_save(child)
        expect_any_instance_of(Person).to receive(:managers).and_raise('ouch')
        expect { household.destroy }.to raise_error('ouch').and(not_change { PeopleManager.count })
      end
    end
  end
end
