# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistrationAbo::MainPerson do
  subject(:model) { described_class.new }

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      address: 'Musterplatz',
      town: 'Zurich',
      email: 'max.muster@example.com',
      zip_code: '8000',
      birthday: '01.01.2000',
      country: 'CH',
      number: '+41 79 123 45 67'
    }
  }

  describe 'validations' do
    it 'validates required fields' do
      model.country = nil
      expect(model).not_to be_valid
      expect(model.errors.attribute_names).to match_array [
        :first_name,
        :last_name,
        :email,
        :address,
        :zip_code,
        :town,
        :birthday,
        :country,
        :number
      ]
    end

    it 'is invalid if number is blank' do
      model.attributes = required_attrs.except(:number)
      expect(model).not_to be_valid
      expect(model.errors.full_messages).to eq ['Mobil muss ausgefüllt werden']
    end

    it 'is invalid if number has invalid format ' do
      model.attributes = required_attrs
      model.number = '1234'
      expect(model).not_to be_valid
      expect(model.errors.full_messages).to eq ['Mobil ist nicht gültig']
    end
  end

  it 'is valid if required attrs are present' do
    model.attributes = required_attrs
    expect(model).to be_valid
  end

  it 'it defaults country to CH' do
    model.attributes = required_attrs.except('country')
    expect(model).to be_valid
    expect(model.country).to eq 'CH'
  end


  it 'is invalid if person is too young' do
    model.attributes = required_attrs.merge(birthday: Date.today)
    expect(model).to have(1).error_on(:base)
    expect(model.errors.full_messages).to eq [
      'Person muss 18 Jahre oder älter sein.'
    ]
  end
end
