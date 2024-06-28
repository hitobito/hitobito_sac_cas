# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Household do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: owner, **attrs)
  end

  let(:person) { Fabricate(:person_with_role, group: groups(:bluemlisalp_mitglieder), role: 'Mitglied', email: 'dad@hitobito.example.com', birthday: Date.new(2000, 1, 1)) }
  let(:adult) { Fabricate(:person_with_role, group: groups(:bluemlisalp_mitglieder), role: 'Mitglied', birthday: Date.new(1999, 10, 5)) }
  let(:child) { Fabricate(:person_with_role, group: groups(:bluemlisalp_mitglieder), role: 'Mitglied', birthday: Date.new(2012, 9, 23)) }
  let(:second_child) { Fabricate(:person_with_role, group: groups(:bluemlisalp_mitglieder), role: 'Mitglied', birthday: Date.new(2014, 4, 13)) }
  let(:second_adult) { Fabricate(:person_with_role, group: groups(:bluemlisalp_mitglieder), role: 'Mitglied', birthday: Date.new(1998, 11, 6)) }

  subject!(:household) { Household.new(person) }

  def sequence = Sequence.by_name(SacCas::Person::Household::HOUSEHOLD_KEY_SEQUENCE)

  before do
    travel_to(Date.new(2024, 5, 31))
  end

  def add_and_save(*members)
    members.each { |member| household.add(member) }
    expect(household.save).to eq true
  end

  def remove_and_save(*members)
    members.each { |member| household.remove(member) }
    expect(household.save).to eq true
  end

  it 'uses sequence for household key' do
    expect do
      household = adult.household
      household.add(child)
      household.save!
    end.to change { sequence.current_value }.by(1)

    expect(adult.reload.household_key).to eq sequence.current_value.to_s
  end

  describe 'validations' do
    it 'is invalid if it contains no adult person' do
      household = Household.new(child)
      household.add(second_child)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(['Der Haushalt enthält keine erwachsene Person mit bestätigter E-Mail Adresse.',
                                                      'Eine Familie muss mindestens 1 erwachsene Person enthalten.'])
    end

    it 'is invalid if it contains more than two adult people' do
      household.add(adult)
      household.add(second_adult)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(['Eine Familie darf höchstens 2 erwachsene Personen enthalten.'])
    end

    it 'is invalid if it contains only one person' do
      household = Household.new(person)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(['Eine Familie muss mindestens 2 Personen enthalten.'])
    end

    it 'is invalid if pending removed person does not have a confirmed email' do
      add_and_save(adult, child)
      adult.update_attribute(:email, '')
      household.remove(adult)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(['Die entfernte Person besitzt keine bestätigte E-Mail Adresse.'])
    end

    it 'is invalid if it contains no adult with confirmed email' do
      adult.update_attribute(:email, '')
      household = Household.new(adult)
      household.add(child)
      expect(household.valid?).to eq false
      expect(household.errors[:base]).to match_array(['Der Haushalt enthält keine erwachsene Person mit bestätigter E-Mail Adresse.'])
    end

    it 'is invalid in destroy context with blank email' do
      person.email = nil

      expect(household.valid?(:destroy)).to eq false
      expect(household.errors['members[0].base']).to match_array(["#{person.full_name} hat keine bestätigte E-Mail Adresse.",
                                                                  "#{person.full_name} hat einen Austritt geplant."])

    end

    it 'is invalid if no household person has a membership role' do
      new_person = Fabricate(
        :person_with_role,
        group: groups(:abo_die_alpen),
        role: Group::AboMagazin::Abonnent.sti_name,
        beitragskategorie: :adult
      )
      other_household_person = Fabricate(
        :person_with_role,
        group: groups(:abo_die_alpen),
        role: Group::AboMagazin::Abonnent.sti_name,
        beitragskategorie: :adult
      )
      household = Household.new(new_person)
      household.add(other_household_person)
      expect(household.valid?).to eq false
      expect(household.errors[:members]).to match_array(["Eine Person in der Familie muss eine Mitgliedschaft in einer Sektion besitzen."])
    end

    it 'is invalid if no person has a membership at all' do
      new_person = Fabricate(:person)
      other_household_person = Fabricate(:person)
      household = Household.new(new_person)
      household.add(other_household_person)
      expect(household.valid?).to eq false
      expect(household.errors[:members]).to match_array(["Eine Person in der Familie muss eine Mitgliedschaft in einer Sektion besitzen."])
    end
  end

  describe 'maintaining sac_family' do
    it 'updates sac_family' do
      add_and_save(adult)
      expect(person.sac_family).to receive(:update!)
      expect(household.save).to eq true
    end

    it 'ignores return value of sac_family#update!' do
      add_and_save(adult)
      expect(person.sac_family).to receive(:update!).and_return(false)
      expect(household.save).to eq true
    end

    it 'does not update sac_family if told to skip' do
      household = Household.new(person, maintain_sac_family: false)
      household.add(adult)
      expect(person.sac_family).not_to receive(:update!)
      expect(household.save).to eq true
    end
  end

  describe 'people manager relations' do
    context 'adding people' do
      it 'noops when adding adult' do
        expect { add_and_save(adult) }.not_to(change { PeopleManager.count })
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
