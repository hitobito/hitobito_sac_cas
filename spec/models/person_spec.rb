# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Person do
  context '#membership_number' do
    it 'is not validated for presence' do
      person = Person.new(first_name: 'John')
      person.valid?
      expect(person.errors.where(:membership_number, :blank)).to be_empty
    end

    it 'is generated automatically' do
      person = Person.create!(first_name: 'John')
      expect(person.membership_number).to be_present
    end

    it 'cannot be changed' do
      person = Person.create!(first_name: 'John')
      expect { person.update!(membership_number: person.membership_number + 1) }.
        not_to (change { person.reload.membership_number })
    end

    it 'cannot be set for new records' do
      person = Person.create!(first_name: 'John', membership_number: 123123)
      expect(person.membership_number).not_to eq 123123
    end

    it 'can be set for new records with Person.allow_manual_membership_number' do
      person = Person.with_manual_membership_number do
        Person.create!(first_name: 'John', membership_number: 123123)
      end
      expect(person.reload.membership_number).to eq 123123
    end

    it 'must be unique' do
      Person.with_manual_membership_number do
        Person.create!(first_name: 'John', membership_number: 123123)
        expect { Person.create!(first_name: 'John', membership_number: 123123) }.
          to raise_error(ActiveRecord::RecordNotUnique, /Duplicate entry/)
      end
    end
  end
end
