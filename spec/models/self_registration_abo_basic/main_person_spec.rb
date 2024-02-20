# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistrationAboBasic::MainPerson do
  subject(:model) { described_class.new }

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      email: 'max.muster@example.com',
      birthday: '01.01.2000',
    }
  }

  describe 'validations' do
    it 'validates required fields' do
      expect(model).not_to be_valid
      expect(model.errors.attribute_names).to match_array [
        :first_name,
        :last_name,
        :email,
        :birthday,
      ]
    end

    it 'is invalid if number has invalid format' do
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

  it 'is does not validate minimum age' do
    model.attributes = required_attrs.merge(birthday: Date.today)
    expect(model).to be_valid
  end
end
