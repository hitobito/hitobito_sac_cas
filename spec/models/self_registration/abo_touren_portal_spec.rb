# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::AboTourenPortal do
  let(:group)  { Fabricate.build(Group::AboTourenPortal.sti_name, parent: groups(:abonnenten)) }
  let(:params) { {} }
  subject(:registration) { described_class.new(params: params, group: group) }

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      email: 'max.muster@example.com',
      birthday: '01.01.2000',
      address_care_of: 'c/o Musterleute',
      street: 'Musterplatz',
      housenumber: '42',
      postbox: 'Postfach 23',
      town: 'Zürich',
      zip_code: '8000',
      number: '+41 79 123 45 67',
      statutes: '1',
      data_protection: '1'
    }
  }

  it 'has main email and emailless_main_person partials' do
    expect(registration.partials).to eq [:main_email, :emailless_main_person]
  end

  it 'has expected main_person class' do
    expect(registration.main_person).to be_kind_of(SelfRegistration::Abo::MainPerson)
  end

  describe 'validations' do
    describe 'main_email' do
      let(:params) { { step: 0 } }

      it 'is valid if email is valid in first step' do
        registration.main_person_attributes = required_attrs.slice(:email)
        allow(Truemail).to receive(:valid?).with(required_attrs[:email]).and_return(true)
        expect(registration).to be_valid
      end

      it 'is invalid if email is invalid in first step' do
        registration.main_person_attributes = required_attrs.slice(:email)
        allow(Truemail).to receive(:valid?).with(required_attrs[:email]).and_return(false)
        expect(registration).not_to be_valid
      end
    end

    describe 'emailless_main_person' do
      let(:params) { { step: 1 } }

      before { group.update!(self_registration_role_type: group.role_types.first) }

      it 'is invalid if only email is present in second step' do
        registration.main_person_attributes = required_attrs.slice(:email)
        expect(registration).not_to be_valid
      end

      it 'is invalid if person is too young' do
        registration.main_person_attributes = required_attrs.merge(birthday: I18n.l(17.years.ago.to_date))
        expect(registration).not_to be_valid
        expect(registration.main_person.errors.full_messages).to eq ['Person muss 18 Jahre oder älter sein.']
      end

      it 'is valid if all required attrs are present in second step' do
        registration.main_person_attributes = required_attrs
        expect(registration).to be_valid
      end
    end
  end

  it '#save! creates person and role' do
    group.update!(self_registration_role_type: group.role_types.first)
    registration.main_person_attributes = required_attrs
    expect { registration.save! }.to change { Person.count }.by(1)
      .and change { Role.count }.by(1)
    expect(Person.find_by(first_name: 'Max').household_key).to be_nil
  end

  describe '#redirect_to_login?' do
    it 'is false if person with email does not exist' do
      registration.main_person_attributes[:email] = 'test@example.com'
      expect(registration).not_to be_redirect_to_login
    end

    it 'is true if person with email exists' do
      registration.main_person.email = 'support@hitobito.example.com'
      expect(registration).to be_redirect_to_login
    end
  end
end
