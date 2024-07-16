# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::Neuanmeldungen::RejectsController do
  before { sign_in(people(:admin)) }

  context "POST create" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
    let(:people_ids) { %i[abonnent mitglied tourenchef].map { |p| people(p).id } }

    subject(:send_request) do
      post :create, params: {group_id: group.id, ids: people_ids.join(","), note: "foo"}
    end

    it "calls People::Neuanmeldungen::Reject::call" do
      rejector = People::Neuanmeldungen::Reject.new
      expect(People::Neuanmeldungen::Reject).to receive(:new).and_return(rejector)
      expect(rejector).to receive(:attributes=).with({
        group: group,
        people_ids: people_ids,
        note: "foo",
        author: people(:admin)
      })
      expect(rejector).to receive(:call)

      send_request
    end

    it "sets the flash message" do
      send_request

      expect(flash[:notice]).to eq("3 Anmeldungen wurden abgelehnt")
    end

    context "with family members" do
      let(:people_ids) { %i[abonnent familienmitglied].map { |p| people(p).id } }

      it "approves all 3 family members and sets the flash message" do
        send_request

        expect(flash[:notice]).to eq("4 Anmeldungen wurden abgelehnt")
      end
    end

    it "redirects to the group people list" do
      send_request

      expect(response).to redirect_to(group_people_path(group_id: group.id))
    end
  end
end
