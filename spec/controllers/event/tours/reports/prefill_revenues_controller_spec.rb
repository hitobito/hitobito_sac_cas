# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Tours::Reports::PrefillRevenuesController do
  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:params) { {group_id: group.id, event_id: event.id} }

  def create_participation(attrs = {})
    Fabricate(:event_participation, attrs.merge(event: event)).tap do
      Fabricate(Event::Role::Participant.sti_name, participation: _1)
    end
  end

  before do
    allow_any_instance_of(Event::Tour).to receive(:reportable?).and_return(true)
    create_participation(price_category: "price_member", price: 10)
    create_participation(price_category: "price_member", price: 10)
    create_participation(price_category: "price_member", price: 20)
    create_participation(price_category: "price_special", price: 40)

    sign_in(person)
  end

  describe "GET#show" do
    context "as mitglied" do
      let(:person) { people(:mitglied) }

      it "is unauthorized" do
        expect { get :show, params: params }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      let(:person) { people(:admin) }

      it "is unauthorized when event is not reportable" do
        allow_any_instance_of(Event::Tour).to receive(:reportable?).and_return(false)

        expect { get :show, params: params }.to raise_error(CanCan::AccessDenied)
      end

      it "returns revenue rows grouped by price_category and price" do
        get :show, params: params

        expect(response).to be_successful
        expect(response.parsed_body).to match_array [
          {"description" => "Kosten SAC-Mitglied (extern)", "count" => 2, "amount" => "10.00"},
          {"description" => "Kosten SAC-Mitglied (extern)", "count" => 1, "amount" => "20.00"},
          {"description" => "Kosten SAC Sektionsmitglied", "count" => 1, "amount" => "40.00"},
          {"description" => "Kosten nicht-SAC-Mitglied (Gast)", "count" => 0, "amount" => "0.00"}
        ]
      end

      it "filters out participations with nil price_category" do
        create_participation(price_category: nil, price: 40)

        get :show, params: params

        expect(response.parsed_body.pluck("description")).not_to include(nil)
      end

      it "filters out participations with price zero" do
        create_participation(price_category: "price_member", price: 0)

        get :show, params: params

        expect(response.parsed_body.pluck("description")).not_to include(nil)
      end

      it "returns category with count zero" do
        event.participations.destroy_all

        get :show, params: params

        expect(response).to be_successful
        expect(response.parsed_body).to match_array [
          {"description" => "Kosten SAC-Mitglied (extern)", "count" => 0, "amount" => "0.00"},
          {"description" => "Kosten SAC Sektionsmitglied", "count" => 0, "amount" => "0.00"},
          {"description" => "Kosten nicht-SAC-Mitglied (Gast)", "count" => 0, "amount" => "0.00"}
        ]
      end
    end
  end
end
