# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistrationNeuanmeldung::MainPerson do
  subject(:model) { described_class.new }
  subject(:role) { model.role }
  let(:sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  describe 'attribute assignments accept additiional attributes' do
    it 'works via constructor for symbols' do
      expect(described_class.new(address: 'test').address).to eq 'test'
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

  describe 'default values' do
    it 'sets country to CH' do
      expect(model.country).to eq 'CH'
    end
  end

  describe 'validations' do
    it 'validates required fields' do
      model.country = nil
      expect(model).not_to be_valid
      expect(model.errors.attribute_names).to match_array [
        :first_name,
        :last_name,
        :email,
        :address,
        :zip_code,
        :town,
        :birthday,
        :country,
        :phone_numbers
      ]
    end

    it 'is invalid if phone_nuber is missing' do
      model.attributes = required_attrs.except(:phone_numbers_attributes)
      expect(model).not_to be_valid
      expect(model.errors.full_messages).to eq ['Telefon muss ausgefüllt werden']
    end

    it 'is valid if required attrs are set' do
      model.attributes = required_attrs
      expect(model).to be_valid
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

  describe 'role' do
    it 'builds role with expected type' do
      model.primary_group = groups(:bluemlisalp_neuanmeldungen_sektion)
      expect(role).to be_kind_of(Group::SektionsNeuanmeldungenSektion::Neuanmeldung)
    end
  end

  describe 'supplements' do
    let(:supplements) { SelfRegistrationNeuanmeldung::Supplements.new({}, groups(:bluemlisalp_mitglieder)) }

    subject(:role) { model.role }

    before { model.supplements = supplements }

    it 'assigns self_registration_reason_id' do
      supplements.self_registration_reason_id = 123
      expect(model.self_registration_reason_id).to eq 123
    end

    it 'sets privacy_policy_accepted_at' do
      supplements.statutes = true
      supplements.data_protection = true
      supplements.contribution_regulations = true
      supplements.sektion_statuten = true
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

    describe 'newsletter' do
      let(:root) { groups(:root) }
      let!(:list) { Fabricate(:mailing_list, group: root) }

      before do
        root.update!(sac_newsletter_mailing_list_id: list.id)
        model.primary_group = groups(:bluemlisalp_neuanmeldungen_sektion)
        model.attributes = required_attrs
      end

      it 'creates excluding subscription' do
        model.save!
        expect(model.person.subscriptions.excluded.where(mailing_list: list)).to be_exist
      end

      it 'does not create excluding subscription if newsletter is set to 1' do
        supplements.newsletter = 1
        model.save!
        expect(model.person.subscriptions.excluded.where(mailing_list: list)).not_to be_exist
      end

      it 'does not fail if list does not exist' do
        list.destroy!
        model.save!
        expect(model.person.subscriptions.excluded.where(mailing_list: list)).not_to be_exist
      end
    end
  end
end
