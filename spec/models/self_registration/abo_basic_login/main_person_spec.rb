# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::AboBasicLogin::MainPerson do
  subject(:model) { described_class.new }

  let(:required_attrs) {
    {
      first_name: 'Max',
      last_name: 'Muster',
      email: 'max.muster@example.com',
      birthday: '01.01.2000',
      statutes: '1',
      data_protection: '1'
    }
  }

  describe 'default values' do
    it 'sets country to CH' do
      expect(model.country).to eq 'CH'
    end
  end

  describe 'validations' do
    it 'is invalid if required attrs are not set' do
      expect(model).not_to be_valid
      expect(model).to have(1).error_on(:first_name)
      expect(model).to have(1).error_on(:last_name)
      expect(model).to have(1).error_on(:email)
      expect(model).to have(1).error_on(:birthday)
      expect(model).to have(1).error_on(:statutes)
      expect(model).to have(1).error_on(:data_protection)
    end

    it 'is valid if required attrs are set' do
      model.attributes = required_attrs
      expect(model).to be_valid
    end

    it 'is invalid if number is invalid' do
      model.attributes = required_attrs.merge(number: '079123')
      expect(model).not_to be_valid
      expect(model.errors.full_messages).to eq ['Telefon ist nicht gültig']
    end
  end

  describe '#save!' do
    let(:group) { Fabricate.build(Group::AboBasicLogin.sti_name, parent: groups(:abonnenten)) }

    before do
      group.update!(self_registration_role_type: group.role_types.first)
      model.attributes = required_attrs.merge(primary_group: group)
    end

    it 'persists attributes' do
      expect do
        model.save!
      end.to change { Person.count }.by(1)
        .and change { group.roles.count }.by(1)

      person = Person.find_by(email: 'max.muster@example.com')
      expect(person.first_name).to eq 'Max'
      expect(person.last_name).to eq 'Muster'
      expect(person.birthday).to eq Date.new(2000, 1, 1)
    end

    describe 'newsletter' do
      let(:root) { groups(:root) }
      let!(:list) { Fabricate(:mailing_list, group: root) }

      before do
        root.update!(sac_newsletter_mailing_list_id: list.id)
      end

      it 'creates excluding subscription' do
        model.save!
        expect(model.person.subscriptions.excluded.where(mailing_list: list)).to be_exist
      end

      it 'does not create excluding subscription if newsletter is set to 1' do
        model.newsletter = 1
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
