# frozen_string_literal: true

# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe ExternalInvoiceResource, type: :resource do
  let(:person) { admin }
  let!(:invoice) {
    Fabricate(:external_invoice, person: admin, total: 15, sent_at: "2024-08-01",
      link: groups(:bluemlisalp))
  }
  let(:admin) { people(:admin) }

  describe "updating" do
    def payload(**attrs)
      {
        data: {
          id: invoice.id.to_s,
          type: "external_invoices",
          attributes: attrs.to_h
        }
      }
    end

    it "can update state attribute" do
      instance = ExternalInvoiceResource.find(payload(state: :payed))
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { invoice.reload.state }.from("open").to("payed")
    end

    it "can update total attribute" do
      instance = ExternalInvoiceResource.find(payload(total: 99))
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { invoice.reload.total }.from(15).to(99)
    end

    it "can update sent_at attribute" do
      instance = ExternalInvoiceResource.find(payload(sent_at: "2024-08-02"))
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { invoice.reload.sent_at.to_s }.from("2024-08-01").to("2024-08-02")
    end

    [:person_id, :type, :link_id, :link_type, :issued_at, :year,
      :abacus_sales_order_key].each do |attr|
      it "cannot update #{attr}" do
        data = {}
        data[attr] = 1
        expect {
          ExternalInvoiceResource.find(payload(**data))
        }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end
  end
end
