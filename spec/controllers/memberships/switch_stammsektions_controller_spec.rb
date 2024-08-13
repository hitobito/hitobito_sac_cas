# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::SwitchStammsektionsController do
  let(:current_user) { people(:admin) }
  let(:person) { people(:mitglied) }
  let(:matterhorn) { groups(:matterhorn) }
  let(:stammsektion_role) { person.sac_membership.stammsektion_role }

  def wizard_params(step: 0, **attrs)
    {
      group_id: stammsektion_role.group_id,
      person_id: person.id,
      step: step
    }.merge(wizards_memberships_switch_stammsektion: attrs)
  end

  before { sign_in(current_user) }

  context "single person" do
    before { roles(:mitglied_zweitsektion).destroy }

    it "response with 422 when flash message" do
      post :create, params: wizard_params(choose_sektion: {group_id: groups(:root).id})
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "sets flash message" do
      post :create, params: wizard_params(step: 1, choose_sektion: {group_id: matterhorn.id})
      expect(response).to redirect_to(person_path(person, format: :html))
      expect(flash[:notice]).to eq "Dein Sektionswechsel zu <i>SAC Matterhorn</i> wurde vorgenommen."
    end
  end

  context "family" do
    let(:person) { people(:familienmitglied) }

    it "sets flash message" do
      roles(:familienmitglied_zweitsektion).destroy
      roles(:familienmitglied2_zweitsektion).destroy

      post :create, params: wizard_params(step: 1, choose_sektion: {group_id: matterhorn.id})
      expect(response).to redirect_to(person_path(person, format: :html))
      expect(flash[:notice]).to eq "Eure 3 Sektionswechsel zu <i>SAC Matterhorn</i> wurden vorgenommen."
    end
  end
end
