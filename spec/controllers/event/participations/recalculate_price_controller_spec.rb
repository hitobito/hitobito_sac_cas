# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Participations::RecalculatePriceController do
  let(:admin) { people(:admin) }
  let(:participant) { people(:mitglied) }
  let(:event) { Fabricate(:sac_open_course, price_member: 5, price_regular: 10) }
  let(:group) { event.groups.first }
  let(:participation) {
    Fabricate(:event_participation, event:, participant: participant, price: 10,
      price_category: "price_regular", application_id: -1)
  }
  let(:params) { {group_id: group.id, event_id: event.id, id: participation.id} }

  describe "GET#index" do
    describe "event_participation" do
      context "as participant" do
        before { sign_in(participant) }

        it "is unauthorized" do
          params[:event_participation_invoice_form] = {price_category: "price_member"}

          expect { get :index, params: }.to raise_error(CanCan::AccessDenied)
        end
      end

      context "as admin" do
        before { sign_in(admin) }

        it "recalculates price based on price category" do
          params[:event_participation] = {price_category: "price_member"}
          get :index, params: params
          expect(JSON.parse(response.body)["value"]).to eq "5.00"
        end

        it "recalculates price with empty price category" do
          params[:event_participation] = {price_category: ""}
          get :index, params: params
          expect(JSON.parse(response.body)["value"]).to eq "0.00"
        end

        it "returns unprocessable_entity when invalid price_category is passed" do
          params[:event_participation] = {price_category: "this_price_category_doesnt_exist"}
          get :index, params: params
          expect(response.status).to eq 422
        end

        it "returns not found when unknown query param is passed" do
          params[:event_participation] = {unknown_query_param: "price_member"}
          get :index, params: params
          expect(response.status).to eq 400
        end
      end
    end

    describe "event_participation_invoice_form" do
      context "as participant" do
        before { sign_in(participant) }

        it "is unauthorized" do
          params[:event_participation_invoice_form] = {price_category: "price_member"}

          expect { get :index, params: }.to raise_error(CanCan::AccessDenied)
        end
      end

      context "as admin" do
        before { sign_in(admin) }

        it "is unauthorized for leader participations" do
          Fabricate(Event::Course::Role::Leader.name.to_sym, participation: participation)
          params[:event_participation_invoice_form] = {price_category: "price_member"}

          expect { get :index, params: }.to raise_error(CanCan::AccessDenied)
        end

        it "recalculates price when price_category changed" do
          params[:event_participation_invoice_form] = {price_category: "price_member"}
          get :index, params: params
          expect(JSON.parse(response.body)["value"]).to eq "5.00"
        end

        it "returns unprocessable_content when invalid price_category is passed" do
          params[:event_participation_invoice_form] =
            {price_category: "this_price_category_doesnt_exist"}
          get :index, params: params
          expect(response.status).to eq 422
        end

        it "recalculates price when reference_date changed" do
          params[:event_participation_invoice_form] = {reference_date: "12.12.2025"}
          get :index, params: params
          expect(JSON.parse(response.body)["value"]).to eq "10.00"
        end

        it "returns unprocessable_content when invalid reference_date is passed" do
          params[:event_participation_invoice_form] = {reference_date: "12.12"}
          get :index, params: params
          expect(response.status).to eq 422
        end

        it "returns not found when unknown query param is passed" do
          params[:event_participation_invoice_form] = {unknown_query_param: "price_member"}
          get :index, params: params
          expect(response.status).to eq 400
        end
      end
    end
  end
end
