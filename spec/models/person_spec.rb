# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Person do
  context 'family_id' do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { Fabricate(:person, household_key: '1234ABCD', birthday: 25.years.ago, primary_group: group) }

    it 'is blank for person without role having beitragskategorie=familie' do
      assert(person.roles.empty?)
      expect(person.family_id).to be_nil
    end

    context 'with role having beitragskategorie=familie' do
      before do
        person.roles.create!(type: Group::SektionsMitglieder::Mitglied.name, group: group)
      end

      it 'returns prefixed household_key for person' do
        expect(person.reload.family_id).to eq "F#{person.household_key}"
      end

      it 'does not prefix household_key if already prefixed' do
        person.household_key = "F42"
        expect(person.family_id).to eq "F42"
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

  describe '#salutation_label' do
    subject(:person) { Fabricate.build(:person) }

    ['m', 'w', nil].zip(%w(Mann Frau Andere)).each do |value, label|
      it "is #{label} for #{value}" do
        expect(person.salutation_label(value)).to eq label
      end
    end
  end
end
