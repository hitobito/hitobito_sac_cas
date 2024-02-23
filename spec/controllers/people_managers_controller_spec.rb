# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

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
