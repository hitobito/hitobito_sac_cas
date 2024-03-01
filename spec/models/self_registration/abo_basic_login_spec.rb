# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::AboBasicLogin do
  let(:group)  { Fabricate.build(Group::AboBasicLogin.sti_name, parent: groups(:abonnenten)) }
  let(:params) { {} }
  subject(:registration) { described_class.new(params: params, group: group) }

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      email: 'max.muster@example.com',
      birthday: '1.1.2000',
      statutes: '1',
      data_protection: '1'
    }
  }

  it 'has main email and emailless_main_person partials' do
    expect(registration.partials).to eq [:main_email, :emailless_main_person]
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
