# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "external_invoices#index", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let!(:token) {
      service_tokens(:permitted_root_layer_token).token
    }
    let!(:external_invoices) do
      Array.new(3) {
        Fabricate(:external_invoice, person: people(:admin), link: groups(:bluemlisalp))
      } +
        Array.new(4) {
          Fabricate(:external_invoice, person: people(:mitglied), link: groups(:bluemlisalp))
        }
    end
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/external_invoices", params:
    end

    describe "basic fetch" do
      it "works" do
        expect(ExternalInvoiceResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["external_invoices"])
        expect(d.map(&:id)).to match_array(external_invoices.pluck(:id))
      end
    end

    describe "filters by person" do
      let(:person) { people(:mitglied) }
      let(:params) { {filter: {person_id: person.id}} }

      it "correctly" do
        expect(ExternalInvoiceResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["external_invoices"])
        expect(d.map(&:person_id).uniq).to match_array([person.id.to_s])
      end
    end

    describe "check if other filters work" do
      let(:person) { people(:mitglied) }
      let(:params) {
        {filter: {link_type: "", link_id: "", issued_at: "", year: "", abacus_sales_order_key: "",
                  state: ""}}
      }

      it "correctly" do
        expect(ExternalInvoiceResource).to receive(:all).and_call_original
        # this will fail if filters are not allowed
        make_request
        expect(response.status).to eq(200), response.body
      end
    end
  end
end
