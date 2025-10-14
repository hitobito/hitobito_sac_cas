# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

shared_examples "people_managers#create" do
  include Households::SpecHelper
  before { sign_in(people(:admin)) }

  def create_person(**opts)
    Fabricate(:person, primary_group: groups(:bluemlisalp_mitglieder), **opts).tap do |person|
      # add a role to make the person findable
      # rubocop:todo Layout/LineLength
      Group::SektionsMitglieder::Mitglied.create!(person: person, group: groups(:bluemlisalp_mitglieder),
        # rubocop:enable Layout/LineLength
        start_on: 1.year.ago, delete_on: 2.years.from_now)
    end
  end

  context "#create" do
    let(:manager) { create_person(birthday: 25.years.ago) }
    let(:managed) { create_person(birthday: 15.years.ago) }

    let(:params) do
      attr = (described_class.assoc == :people_managers) ? :manager_id : :managed_id
      if attr == :manager_id
        {person_id: managed.id, people_manager: {attr => manager.id}}
      else
        {person_id: manager.id, people_manager: {attr => managed.id}}
      end
    end

    it "adds manager to household" do
      manager.update!(sac_family_main_person: true)
      managed.update!(household_key: "the-household")
      expect(manager.household_key).to be_nil

      expect { post :create, params: params }
        .to change { PeopleManager.count }.by(1)
        .and change { manager.reload.household_key }.from(nil).to("the-household")
        .and not_change { managed.reload.household_key }
    end

    it "adds managed to household" do
      managed.update!(sac_family_main_person: true)
      manager.update!(household_key: "the-household")
      expect(managed.household_key).to be_nil

      expect { post :create, params: params }
        .to change { PeopleManager.count }.by(1)
        .and not_change { manager.reload.household_key }
        .and change { managed.reload.household_key }.from(nil).to("the-household")
    end

    it "creates new household" do
      managed.update!(sac_family_main_person: true)
      expect(manager.household_key).to be_nil
      expect(managed.household_key).to be_nil

      expect { post :create, params: params }
        .to change { PeopleManager.count }.by(1)
        .and change { manager.reload.household_key }.from(nil)
        .and change { managed.reload.household_key }.from(nil)

      expect(manager.household_key).to eq(managed.household_key)
    end

    it "does not persist if household is invalid" do
      expect_any_instance_of(Household).to receive(:valid?).and_return(false)

      expect { post :create, params: params }
        .to not_change { PeopleManager.count }
        .and not_change { manager.reload.household_key }
        .and not_change { managed.reload.household_key }
    end
  end
end

shared_examples "people_managers#destroy" do
  include Households::SpecHelper
  before do
    sign_in(people(:admin))
    create_household(parent, parent2, child)
  end

  def create_person(**opts)
    Fabricate(:person, primary_group: groups(:bluemlisalp_mitglieder), **opts).tap do |person|
      # add a role to make the person findable
      # rubocop:todo Layout/LineLength
      Group::SektionsMitglieder::Mitglied.create!(person: person, group: groups(:bluemlisalp_mitglieder),
        # rubocop:enable Layout/LineLength
        created_at: 1.year.ago, delete_on: 2.years.from_now)
    end
  end

  let(:parent) { create_person(birthday: 25.years.ago, sac_family_main_person: true) }
  let(:child) { create_person(birthday: 15.years.ago) }
  let(:parent2) { create_person(birthday: 25.years.ago) }
  let(:entry) { PeopleManager.find_or_create_by(manager_id: parent.id, managed_id: child.id) }

  def params
    attr = (described_class.assoc == :people_managers) ? :managed_id : :manager_id
    {
      id: entry.id,
      person_id: entry.send(attr)
    }
  end

  context "#destroy" do
    it "removes managed from household" do
      delete :destroy, params: params

      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(child.reload.household_key).to be_blank
      expect(parent.household_people).to contain_exactly(parent2)
    end

    it "removes managed from all managers" do
      delete :destroy, params: params

      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(parent.reload.people_manageds).to be_empty
      expect(parent2.reload.people_manageds).to be_empty
    end
  end
end
