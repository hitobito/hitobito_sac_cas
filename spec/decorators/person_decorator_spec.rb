# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe PersonDecorator do
  let(:person) do
    Fabricate.build(:person, {
      id: 123,
      first_name: 'Max',
      last_name: 'Muster',
      nickname: 'Maxi',
      zip_code: 8000,
      town: 'Zürich',
      birthday: '14.2.2014'
    })
  end

  describe '#as_typeahead' do
    subject(:label) { person.decorate.as_typeahead[:label] }

    it 'has id and label' do
      expect(person.decorate.as_typeahead[:id]).to eq 123
      expect(person.decorate.as_typeahead[:label]).to be_present
    end

    it 'includes town and year of birth' do
      expect(label).to eq 'Max Muster / Maxi, Zürich (2014; 123)'
    end

    it 'ommits year of birth if missing' do
      person.birthday = nil
      expect(label).to eq 'Max Muster / Maxi, Zürich (123)'
    end

    it 'ommits town if missing' do
      person.town = nil
      expect(label).to eq 'Max Muster / Maxi (2014; 123)'
    end

    it 'ommits town if missing' do
      person.company = true
      person.company_name = 'Coorp'
      expect(label).to eq 'Coorp, Zürich (Max Muster) (2014; 123)'
    end
  end
end
