# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "ExternalInvoices#show", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let!(:external_invoice) { Fabricate(:external_invoice, person: people(:admin), link: group) }
    let(:token) { service_tokens(:permitted_root_layer_token).token }
    let(:group) { groups(:bluemlisalp) }

    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/external_invoices/#{external_invoice.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(ExternalInvoiceResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.jsonapi_type).to eq("external_invoices")
        expect(d.id).to eq(external_invoice.id)
      end
    end
  end
end
