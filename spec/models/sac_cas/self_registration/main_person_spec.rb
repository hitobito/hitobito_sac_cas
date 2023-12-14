# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::MainPerson do
  subject(:model) { described_class.new }

  it 'is a Housemate' do
    expect(model).to be_kind_of(SelfRegistration::Person)
  end

  describe 'attribute assignments accept additiional attributes' do
    it 'works via constructor for symbols' do
      expect(described_class.new(address: 'test').address).to eq 'test'
    end
  end

  describe 'validations' do
    it 'validates required fields' do
      expect(model).not_to be_valid
      expect(model.errors.attribute_names).to match_array [
        :first_name,
        :last_name,
        :email,
        :address,
        :zip_code,
        :town,
        :birthday
      ]
    end
  end

  describe 'delegations' do
    it 'reads phone_numbers from person' do
      model.phone_numbers_attributes = {
        '1' => { number: '079' }
      }
      expect(model.phone_numbers).to have(1).item
    end
  end

  describe 'privacy policy' do
    it 'assigns value' do
      model.privacy_policy_accepted = '1'
      expect(model.person.privacy_policy_accepted).to be_truthy
    end

    it 'validates that policy is accepted' do
      model.privacy_policy_accepted = '0'
      expect(model).not_to be_valid
      expect(model).to have(1).error_on(:base)
      expect(model.errors[:base].first).to start_with 'Um die Registrierung'
    end
  end

  describe 'tags' do
    it 'assigns newsletter as tag' do
      model.newsletter = 1
      expect(model.person.tag_list).to eq ['newsletter']
    end

    it 'assigns promocode as tag' do
      model.promocode = :test
      expect(model.person.tag_list).to eq ['promocode']
    end
  end
end
