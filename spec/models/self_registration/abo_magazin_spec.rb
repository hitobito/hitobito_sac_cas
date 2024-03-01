# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#
require 'spec_helper'

describe SelfRegistration::AboMagazin do
  let(:group)  { groups(:abo_die_alpen) }
  let(:params) { {} }
  subject(:registration) { described_class.new(params: params, group: group) }

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      email: 'max.muster@example.com',
      birthday: '01.01.2000',
      address: 'Musterplatz',
      town: 'Zürich',
      zip_code: '8000',
      number: '+41 79 123 45 67',
      statutes: '1',
      data_protection: '1'
    }
  }

  it 'has main email emailless_main_person and issue_date partials' do
    expect(registration.partials).to eq [:main_email, :emailless_main_person, :abo_issue]
  end

  describe 'validations' do
    describe 'main_email' do
      let(:params) { { step: 0 } }

      it 'is valid if email is present in first step' do
        registration.main_person_attributes = required_attrs.slice(:email)
        expect(registration).to be_valid
      end
    end

    describe 'emailless_main_person' do
      let(:params) { { step: 1 } }

      before { group.update!(self_registration_role_type: group.role_types.first) }

      it 'is invalid if only email is present in second step' do
        registration.main_person_attributes = required_attrs.slice(:email)
        expect(registration).not_to be_valid
      end

      it 'is valid if all required attrs are present in second step' do
        registration.main_person_attributes = required_attrs
        expect(registration).to be_valid
      end
    end

    describe 'issue_date' do
      let(:params) { { step: 2 } }

      before { group.update!(self_registration_role_type: group.role_types.first) }

      it 'is valid if all required attrs are present' do
        registration.main_person_attributes = required_attrs
        expect(registration).to be_valid
      end

      it 'is valid if issues_from is from tomorrow' do
        registration.main_person_attributes = required_attrs
        registration.issues_from = Date.tomorrow.to_s
        expect(registration).to be_valid
      end

      it 'is invalid if issues_from is from yesterday' do
        registration.main_person_attributes = required_attrs
        registration.issues_from = Date.yesterday.to_s
        expect(registration).not_to be_valid
        expect(registration).to have(1).error_on(:issues_from)
      end
    end
  end

  describe '#save!' do
    it 'creates person and role' do
      group.update!(self_registration_role_type: group.role_types.first)
      registration.main_person_attributes = required_attrs
      expect { registration.save! }.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
      expect(Person.find_by(first_name: 'Max').household_key).to be_nil
    end

    it 'creates role if abo starts in the future' do
      group.update!(self_registration_role_type: group.role_types.first)
      registration.main_person_attributes = required_attrs
      registration.issues_from = Date.tomorrow
      expect { registration.save! }.to change { Person.count }.by(1)
        .and change { FutureRole.count }.by(1)
      expect(Person.find_by(first_name: 'Max').household_key).to be_nil
    end
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
