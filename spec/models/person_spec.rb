# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Person do
  context 'family_id' do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { Fabricate(:person, household_key: '1234ABCD', birthday: 25.years.ago) }

    it 'is blank for person without role having beitragskategorie=familie' do
      assert(person.roles.empty?)
      expect(person.family_id).to be_nil
    end

    context 'with role having beitragskategorie=familie' do
      before do
        Fabricate(Group::SektionsMitglieder::Mitglied.name, group: group, person: person)
      end

      it 'returns prefixed household_key for person' do
        expect(person.reload.family_id).to eq "F#{person.household_key}"
      end

      it 'does not prefix household_key if already prefixed' do
        person.household_key = 'F42'
        expect(person.family_id).to eq 'F42'
      end
    end
  end

  context '#membership_number (id)' do
    it 'is generated automatically' do
      person = Person.create!(first_name: 'John')
      expect(person.membership_number).to be_present
    end

    it 'can be set for new records' do
      person = Person.create!(first_name: 'John', membership_number: 123_123)
      expect(person.reload.id).to eq 123_123
    end

    it 'must be unique' do
      Person.create!(first_name: 'John', membership_number: 123_123)
      expect { Person.create!(first_name: 'John', membership_number: 123_123) }.
        to raise_error(ActiveRecord::RecordNotUnique, /Duplicate entry/)
    end
  end

  context '#membership_years' do
    let(:person) { Fabricate(:person) }

    let(:created_at) { Time.zone.parse('01-01-2000 12:00:00') }
    let(:end_at) { created_at + 364.days }

    def person_with_membership_years
      Person.with_membership_years.find(person.id)
    end

    def create_role(**attrs)
      Fabricate(Group::SektionsMitglieder::Mitglied.name,
                group: groups(:bluemlisalp_mitglieder),
                person: person,
                **attrs.reverse_merge(created_at: created_at))
    end

    it 'raises error when not using scope :with_membership_years' do
      expect { person.membership_years }.
        to raise_error(RuntimeError, /use Person scope :with_membership_years/)
    end

    it 'is 0 for person without membership role' do
      assert(person.roles.empty?)
      expect(person_with_membership_years.membership_years).to eq 0
    end

    it 'includes membership_years of deleted roles' do
      create_role(created_at: created_at, deleted_at: end_at)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it 'includes membership_years of archived roles' do
      create_role(created_at: created_at, archived_at: end_at)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it 'includes membership_years of role to be deleted' do
      create_role(created_at: created_at, delete_on: end_at)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it 'with multiple membership roles returns the sum of role.membership_years' do
      create_role(created_at: created_at, delete_on: created_at + 365.days)
      create_role(created_at: created_at + 2.years, delete_on: created_at + 2.years + 365.days)
      expect(person_with_membership_years.membership_years).to eq 2
    end

    it 'rounds down to full years' do
      role = create_role(delete_on: created_at + 363.days)
      expect(person_with_membership_years.membership_years).to eq 0

      role.update(delete_on: created_at + 364.days)
      expect(person_with_membership_years.membership_years).to eq 1

      role.update(delete_on: created_at + 728.days)
      expect(person_with_membership_years.membership_years).to eq 1

      role.update(delete_on: created_at + 729.days)
      expect(person_with_membership_years.membership_years).to eq 2
    end
  end
end
