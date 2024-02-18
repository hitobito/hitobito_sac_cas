# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

shared_examples 'people_managers#create' do
  before { sign_in(people(:root)) }

  context '#create' do
    let(:manager) { people(:mitglied) }
    let(:managed) { people(:abonnent) }

    let(:params) do
      attr = described_class.assoc == :people_managers ? :manager_id : :managed_id
      if attr == :manager_id
        { person_id: managed.id, people_manager: { attr => manager.id } }
      else
        { person_id: manager.id, people_manager: { attr => managed.id } }
      end
    end

    it 'adds manager to household' do
      expect(manager.household_key).to be_nil
      managed.update!(household_key: 'the-household')

      expect { post :create, params: params }.
        to change { PeopleManager.count }.by(1).
        and change { manager.reload.household_key }.from(nil).to('the-household').
        and not_change { managed.reload.household_key }
    end

    it 'adds managed to household' do
      manager.update!(household_key: 'the-household')
      expect(managed.household_key).to be_nil

      expect { post :create, params: params }.
        to change { PeopleManager.count }.by(1).
        and not_change { manager.reload.household_key }.
        and change { managed.reload.household_key }.from(nil).to('the-household')
    end

    it 'creates new household' do
      expect(manager.household_key).to be_nil
      expect(managed.household_key).to be_nil

      expect { post :create, params: params }.
        to change { PeopleManager.count }.by(1).
        and change { manager.reload.household_key }.from(nil).
        and change { managed.reload.household_key }.from(nil)

      expect(manager.household_key).to eq(managed.household_key)
    end

    it 'does not persist if household is invalid' do
      expect_any_instance_of(SacCas::Person::Household).to receive(:valid?).and_return(false)

      expect { post :create, params: params }.
        to not_change { PeopleManager.count }.
        and not_change { manager.reload.household_key }.
        and not_change { managed.reload.household_key }
    end
  end
end

shared_examples 'people_managers#destroy' do
  before { sign_in(people(:root)) }

  let(:child) { people(:familienmitglied_kind) }
  let(:parent) { people(:familienmitglied) }
  let(:parent2) { people(:familienmitglied2) }
  let(:entry) { PeopleManager.find_by(manager_id: parent.id, managed_id: child.id) }

  def params
    attr = described_class.assoc == :people_managers ? :managed_id : :manager_id
    {
      id: entry.id,
      person_id: entry.send(attr)
    }
  end

  context '#destroy' do
    it 'removes managed from household' do
      delete :destroy, params: params

      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(child.reload.household_key).to be_blank
      expect(parent.household_people).to contain_exactly(parent2)
    end

    it 'removes managed from all managers' do
      delete :destroy, params: params

      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(parent.reload.people_manageds).to be_empty
      expect(parent2.reload.people_manageds).to be_empty
    end
  end
end
