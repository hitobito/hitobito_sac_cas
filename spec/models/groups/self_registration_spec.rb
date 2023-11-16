# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Groups::SelfRegistration do
  let(:group) { groups(:geschaeftsstelle) }
  let(:params) { {} }

  subject(:registration) { build(params) }

  def build(params)
    nested_params = { groups_self_registration: params }
    described_class.new(group: group, params: nested_params)
  end

  before do
    allow(group).to receive(:self_registration_role_type).and_return(Group::Geschaeftsstelle::ITSupport)
  end

  describe 'constructor' do
    it 'does not fail on empty params' do
      expect { build({}) }.not_to raise_error
    end

    it 'does populate person attrs' do
      registration = build(person_attributes: { first_name: 'test' })
      expect(registration.person_attributes).to be_present
      expect(registration.person.first_name).to eq 'test'
      expect(registration.person).to be_kind_of(Groups::SelfRegistrations::MainPerson)
    end

    it 'does populate person phone number attributes' do
      registration = build(person_attributes: { first_name: 'test', phone_numbers_attributes: { key: { number: '079', public: 0 } } })
      expect(registration.person_attributes).to be_present
      expect(registration.person.phone_numbers.first.number).to eq '079'
    end


    it 'does populate housemates attrs' do
      registration = build(housemates_attributes: { key: { first_name: 'test' } })
      expect(registration.person_attributes).to be_blank
      expect(registration.person.first_name).to be_blank
      expect(registration.housemates_attributes).to be_present
      expect(registration.housemates.first).to be_kind_of(Groups::SelfRegistrations::Housemate)
      expect(registration.housemates.first.first_name).to eq 'test'
      expect { registration.save }.to raise_error
    end
  end

  describe 'others' do
    let(:required_attrs) { [:first_name] }

    before do
      allow(Groups::SelfRegistrations::MainPerson).to receive(:required_attrs).and_return(required_attrs)
      allow(Groups::SelfRegistrations::Housemate).to receive(:required_attrs).and_return(required_attrs)
    end

    describe 'validations' do
      describe 'person' do
        it 'is invalid if attributes are not present' do
          expect(registration).not_to be_valid
          expect(registration.person.errors).to have(1).item
          expect(registration.person.errors[:first_name][0]).to eq 'muss ausgefüllt werden'
        end

        it 'is valid if required attributes are present' do
          registration.person_attributes = { first_name: 'test' }
          expect(registration.person).to be_valid
        end
      end

      describe 'housemates' do
        let(:params) { { person_attributes: { first_name: 'test' } } }

        it 'is invalid because housemate is invalid' do
          registration.housemates_attributes = [{}]
          expect(registration).not_to be_valid
          expect(registration.person).to be_valid
          expect(registration.housemates.first.errors).to have(1).item
        end

        it 'is valid with email and name' do
          registration.housemates_attributes = [{first_name: 'test'}]
          expect(registration).to be_valid
          expect(registration.housemates.first).to be_valid
        end

        it 'is invalid if any housemate is invalid email and name' do
          registration.housemates_attributes = [{}, {first_name: 'test'}]
          expect(registration).not_to be_valid
          expect(registration.housemates.first).not_to be_valid
          expect(registration.housemates.second).to be_valid
        end
      end

      describe 'save!' do
        it 'saves person with role outside of household' do
          registration.person_attributes = { first_name: 'test' }
          expect { registration.save! }.to change { Person.count }.by(1)
            .and change { Role.count }.by(1)
          expect(Person.find_by(first_name: 'test').household_key).to be_nil
        end

        it 'saves person and housemates with household key' do
          registration.person_attributes = { first_name: 'test' }
          registration.housemates_attributes = [{first_name: 'test'}]
          expect { registration.save! }.to change { Person.count }.by(2)
            .and change { Role.count }.by(2)
          expect(Person.where(first_name: 'test').pluck(:household_key).compact.uniq).to have(1).item
        end
      end
    end
  end

end
