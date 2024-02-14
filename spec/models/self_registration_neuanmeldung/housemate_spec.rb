# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistrationNeuanmeldung::Housemate do
  subject(:model) { described_class.new }
  subject(:role) { model.role }

  describe 'attribute assignments accept additiional attributes' do
    it 'works via constructor for symbols' do
      expect(described_class.new(first_name: 'test').first_name).to eq 'test'
    end
  end

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      birthday: '01.01.2000',
    }
  }

  describe 'validations' do
    it 'validates required fields' do
      expect(model).not_to be_valid
      expect(model.errors.attribute_names).to match_array [
        :first_name,
        :last_name,
        :birthday,
      ]
    end

    it 'is valid if required attrs are set' do
      model.attributes = required_attrs
      expect(model).to be_valid
    end

    it 'is requires email to be valid' do
      model.attributes = required_attrs.merge(email: 'asdfasdf')
      expect(model).to have(1).error_on(:email)
    end

    it 'is requires phone_number to be valid' do
      model.attributes = required_attrs.merge(phone_number: 'asdfasdf')
      expect(model).to have(1).error_on(:phone_number)
    end

    it 'is invalid if too many adults exist' do
      model.attributes = required_attrs.merge(adult_count: 2)
      expect(model).to have(1).error_on(:base)
      expect(model.errors.full_messages[0]).to start_with 'In einer Familienmitgliedschaft'
    end
  end

  describe 'additional_email' do
    it 'is translated correctly' do
      expect(model.class.human_attribute_name(:email)).to eq 'E-Mail (optional)'
    end

    it 'is assigned as one of many additional_emails of person' do
      model.email = 'test@example.com'
      expect(model.person.email).to eq 'test@example.com'
    end
  end

  describe 'phone_number' do
    it 'is translated correctly' do
      expect(model.class.human_attribute_name(:phone_number)).to eq 'Telefon (optional)'
    end

    it 'is assigned as one of many phone_numbers of person' do
      model.phone_number = '+41 79 123 45 56'
      number = model.person.phone_numbers.first
      expect(number.number).to eq '+41 79 123 45 56'
      expect(number.label).to eq 'Haupt-Telefon'
    end
  end

  describe 'role' do
    before { model.primary_group = groups(:bluemlisalp_neuanmeldungen_sektion)  }
    it 'builds role with expected type' do
      expect(role).to be_kind_of(Group::SektionsNeuanmeldungenSektion::Neuanmeldung)
    end
  end

  describe 'supplements' do
    let(:supplements) { SelfRegistrationNeuanmeldung::Supplements.new }


    before { model.supplements = supplements }

    it 'sets privacy_policy_accepted_at' do
      supplements.statutes = true
      supplements.data_protection = true
      supplements.contribution_regulations = true
      supplements.section_statutes = true
      travel_to(Time.zone.local(2023, 3, 12)) do
        expect(model.person.privacy_policy_accepted_at).to be_present
      end
    end

    it 'builds a future role' do
      model.primary_group = groups(:bluemlisalp_neuanmeldungen_sektion)
      supplements.register_on = 'jul'
      travel_to(Time.zone.local(2023, 3, 12)) do
        expect(role).to be_kind_of(FutureRole)
      end
    end
  end
end
