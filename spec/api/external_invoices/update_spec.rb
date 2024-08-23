# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe "external_invoices#update", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:group) { groups(:bluemlisalp) }
    let(:token) { service_tokens(:permitted_root_layer_token).token }
    let!(:external_invoices) do
      Array.new(3) { Fabricate(:external_invoice, person: people(:admin), link: group, state: "open", total: 50, sent_at: "2023-05-25") } +
        Array.new(4) { Fabricate(:external_invoice, person: people(:mitglied), link: group) }
    end

    let(:external_invoice) { external_invoices.first }

    subject(:make_request) do
      Graphiti::Debugger.debug do
        jsonapi_put "/api/external_invoices/#{external_invoice.id}?debug=true", payload
      end
    end

    describe "basic update" do
      let(:payload) do
        {data: {
          id: external_invoice.id.to_s,
          type: "external_invoices",
          attributes: {
            state: "payed",
            total: 100,
            sent_at: "2024-01-01"
          }
        }}
      end

      it "updates the resource" do
        expect(ExternalInvoiceResource).to receive(:find).and_call_original
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { external_invoice.reload.state }.to("payed")
          .and change { external_invoice.reload.total }.to(100)
          .and change { external_invoice.reload.sent_at }.to(Date.new(2024, 1, 1))
      end
    end
  end
end
