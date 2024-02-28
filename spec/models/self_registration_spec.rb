# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration do
  let(:group) { groups(:geschaeftsstelle).tap { |g| g.update!(self_registration_role_type: g.role_types.first) } }
  let(:params) { {} }

  subject(:registration) { build(params) }

  def build(params)
    nested_params = { self_registration: params }
    described_class.new(group: group, params: nested_params)
  end

  describe '::for factory method' do
    [
      [SelfRegistration, Group::SacCas, Group::Sektion],
      [SelfRegistration::AboTourenPortal, Group::AboTourenPortal],
      [SelfRegistration::AboMagazin, Group::AboMagazin],
      [SelfRegistration::AboBasicLogin, Group::AboBasicLogin],
      [SelfRegistrationNeuanmeldung, Group::SektionsNeuanmeldungenNv, Group::SektionsNeuanmeldungenSektion]
    ].each do |registration_class, *group_classes|
      group_classes.each do |group_class|
        it "returns #{registration_class} for #{group_class}" do
          registration = described_class.for(Fabricate.build(:group, type: group_class))
          expect(registration).to eq registration_class
        end
      end
    end
  end

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      address: 'Musterplatz',
    }
  }

  it 'only has main_person partial' do
    expect(registration.partials).to eq [:main_person]
  end

  it 'is valid if required attrs are present' do
    registration.main_person_attributes = required_attrs
    expect(registration).to be_valid
  end

  it '#save! creates person and role' do
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
