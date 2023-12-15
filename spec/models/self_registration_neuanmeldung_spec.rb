# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistrationNeuanmeldung do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:params) { {} }

  subject(:registration) { build(params) }

  def build(params)
    nested_params = { self_registration: params }
    described_class.new(group: group, params: nested_params)
  end

  describe 'constructor' do
    it 'does populate person phone number attributes' do
      registration = build({
        main_person_attributes: { phone_numbers_attributes: { key: { number: '079', public: 0 } } }
      })
      expect(registration.main_person_attributes).to be_present
      expect(registration.main_person.phone_numbers.first.number).to eq '079'
    end
  end

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
      phone_numbers_attributes: {
        '0' => { number: '+41 79 123 45 67', label: 'Privat', public: '1' }
      }
    }
  }

  describe 'main_person' do
    it 'is invalid if person is too young' do
      registration.step = 1
      registration.main_person_attributes = required_attrs.merge(birthday: Date.today)
      expect(registration).not_to be_valid
      expect(registration.main_person).to have(1).error_on(:person)
      expect(registration.main_person).to have(1).error_on(:beitragskategorie)
      expect(registration.main_person.role).to have(1).error_on(:person)
    end

    it 'is invalid if person is too young' do
      registration.step = 1
      registration.main_person_attributes = required_attrs.merge(birthday: Date.today)
      expect(registration).not_to be_valid
      expect(registration.main_person).to have(1).error_on(:person)
      expect(registration.main_person).to have(1).error_on(:beitragskategorie)
      expect(registration.main_person.role).to have(1).error_on(:person)
    end

    it 'is valid if required attrs are present' do
      registration.main_person_attributes = required_attrs
      expect(registration).to be_valid
      expect(registration.main_person.role).to be_valid
      expect(registration.main_person.role.beitragskategorie).to eq 'einzel'
    end

    it '#save! creates person and role' do
      registration.main_person_attributes = required_attrs
      expect { registration.save! }.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
      expect(Person.find_by(first_name: 'Max').household_key).to be_nil
    end
  end

  describe 'housemates' do
    let(:params) { { main_person_attributes: required_attrs } }
    let(:housemate_attrs) {
      {
        first_name: 'Maxine',
        last_name: 'Muster',
        email: 'maxine.muster@example.com',
        birthday: '01.01.2000'
      }
    }

    before { registration.step = 2 }

    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

    it 'is invalid if housemate is empty' do
      registration.housemates_attributes = [{}]

      expect(registration).not_to be_valid
      expect(registration.main_person).to be_valid
      expect(registration.housemates.first.errors).to have(6).attribute_names
    end

    it 'is invalid if any housemate is invalid' do
      registration.housemates_attributes = [{}, housemate_attrs]
      expect(registration).not_to be_valid
      expect(registration.housemates.first).not_to be_valid
      expect(registration.housemates.second).to be_valid
    end

    it 'is invalid if person email is re-used by housemate' do
      registration.housemates_attributes = [
        housemate_attrs.merge(email: required_attrs[:email])
      ]
      expect(registration).not_to be_valid
      expect(registration.housemates.first).not_to be_valid
      expect(registration.housemates).to have(1).error_on(:email)
      expect(registration.main_person).to be_valid
    end

    it 'is valid if housemate has required attrs' do
      registration.housemates_attributes = [housemate_attrs]
      expect(registration).to be_valid
      expect(registration.housemates.first).to be_valid
    end

    it 'is valid if for multiple housemates' do
      registration.housemates_attributes = [
        housemate_attrs,
        housemate_attrs.merge(email: 'max@example.com', first_name: 'Max')
      ]
      expect(registration).to be_valid
      expect(registration.housemates.first).to be_valid
      expect(registration.housemates.second).to be_valid
    end

    it '#save! creates people and roles with household key' do
      registration.housemates_attributes = [
        housemate_attrs,
        housemate_attrs.merge(email: 'max@example.com', first_name: 'Max', birthday: 6.years.ago.to_date)
      ]
      expect { registration.save! }.to change { Person.count }.by(3)
        .and change { Role.count }.by(3)
      expect(Person.find_by(first_name: 'Max').household_key).to be_present
    end
  end

  describe '#save!' do
    it 'saves person with role outside of household' do
      registration.main_person_attributes = { first_name: 'test', birthday: '01.01.2000' }
      expect { registration.save! }.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
      expect(Person.find_by(first_name: 'test').household_key).to be_nil
    end

    it 'saves person and housemates with household key' do
      registration.main_person_attributes = { first_name: 'test', birthday: '01.01.2000' }
      registration.housemates_attributes = [{first_name: 'test', birthday: '01.01.2000'}]
      expect { registration.save! }.to change { Person.count }.by(2)
        .and change { Role.count }.by(2)
      expect(Person.where(first_name: 'test').pluck(:household_key).compact.uniq).to have(1).item
    end
  end
end
