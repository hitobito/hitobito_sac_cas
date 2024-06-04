# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationContactData do
  let(:event) { Fabricate.build(:course) }
  let(:person) { Fabricate.build(:person) }

  describe '::validations' do
    let(:attrs) {
      {
        first_name: 'Max',
        last_name: 'Muster',
        street: 'Musterplatz',
        housenumber: '23',
        email: 'max.muster@example.com',
        zip_code: '8000',
        town: 'Zürich',
        country: 'CH',
        birthday: '01.01.1980',
        phone_numbers_attributes: {
          '0': {
            number: '+41 79 123 45 56',
            public: true,
            translated_label: 'Mobile'
          }
        }
      }.with_indifferent_access
    }
    it 'is valid if required attributes are set' do
      expect(build(attrs)).to be_valid
    end

    it 'is invalid if phone number is blank' do
      attrs[:phone_numbers_attributes]['0']['number'] = ''
      contact_data = build(attrs)
      expect(contact_data).not_to be_valid
      expect(contact_data.errors.full_messages).to eq [
        'Telefon muss ausgefüllt werden'
      ]
      expect(contact_data.person.phone_numbers.first).to have(2).errors_on(:number)
    end

    it 'is invalid if phone number is invalid' do
      attrs[:phone_numbers_attributes]['0']['number'] = 'test'
      contact_data = build(attrs)
      expect(contact_data).not_to be_valid
      expect(contact_data.errors.full_messages).to eq [
        'Telefonnummer ist nicht gültig'
      ]
      expect(contact_data.person.phone_numbers.first).to have(1).error_on(:number)
    end
  end

  def build(attributes)
    Event::ParticipationContactData.new(event, person, attributes)
  end
end
