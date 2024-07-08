# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe HouseholdsController do
  let(:group) { groups(:geschaeftsstelle) }
  let(:person) { people(:admin) }
  let(:params) { {group_id: group.id, person_id: person.id} }

  before { sign_in(person) }

  describe "#destroy" do
    let(:household) { assigns(:entry) }

    it "does not destroy invalid entry" do
      person.update_columns(household_key: 123, email: nil)
      expect do
        delete :destroy, params: params
      end.not_to(change { person.reload.household_key })
      expect(flash[:alert]).to eq ["Anna Admin hat keine bestätigte E-Mail Adresse."]
    end
  end
end
