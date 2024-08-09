# frozen_string_literal: true

# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe ExternalInvoiceResource, type: :resource do
  let(:person) { admin }
  let!(:invoice) { Fabricate(:external_invoice, person: admin, link: groups(:bluemlisalp)) }
  let(:admin) { people(:admin) }
  let(:serialized_attrs) do
    [
      :id,
      :jsonapi_type,
      :abacus_sales_order_key,
      :created_at,
      :issued_at,
      :link_id,
      :link_type,
      :person_id,
      :sent_at,
      :state,
      :type,
      :total,
      :updated_at,
      :year
    ]
  end

  it "serializes expected attributes" do
    render
    data = jsonapi_data[0]
    expect(data.attributes.symbolize_keys.keys)
      .to match_array(serialized_attrs)
  end

  describe "filters" do
    let(:params) { {} }

    describe "person_id" do
      it "is empty if filter does not apply" do
        params[:filter] = {person_id: -1}
        render
        expect(jsonapi_data).to be_empty
      end

      it "is present if filter does apply" do
        params[:filter] = {person_id: admin.id}
        render
        expect(jsonapi_data).to have(1).item
      end
    end

    describe "type" do
      it "is empty if filter does not apply" do
        params[:filter] = {type: "unknown"}
        render
        expect(jsonapi_data).to be_empty
      end

      it "is present if filter does apply" do
        params[:filter] = {type: invoice.type.to_s}
        render
        expect(jsonapi_data).to have(1).item
      end
    end

    describe "issued_at" do
      before { invoice.update!(issued_at: Time.zone.yesterday.noon) }

      it "is empty if filter does not apply" do
        params[:filter] = {issued_at: {gt: Time.zone.today}}
        render
        expect(jsonapi_data).to be_empty
      end

      it "is present if filter does apply" do
        params[:filter] = {issued_at: {lt: Time.zone.today}}
        render
        expect(jsonapi_data).to have(1).item
      end
    end

    describe "year" do
      before { invoice.update!(year: 2024) }

      it "is empty if filter does not apply" do
        params[:filter] = {year: 2023}
        render
        expect(jsonapi_data).to be_empty
      end

      it "is present if filter does apply" do
        params[:filter] = {year: 2024}
        render
        expect(jsonapi_data).to have(1).item
      end
    end

    describe "state" do
      before { invoice.update!(state: :payed) }

      it "is empty if filter does not apply" do
        params[:filter] = {state: :draft}
        render
        expect(jsonapi_data).to be_empty
      end

      it "is present if filter does apply" do
        params[:filter] = {state: :payed}
        render
        expect(jsonapi_data).to have(1).item
      end
    end

    describe "abacus_sales_order_key" do
      before { invoice.update!(abacus_sales_order_key: 1) }

      it "is empty if filter does not apply" do
        params[:filter] = {abacus_sales_order_key: -1}
        render
        expect(jsonapi_data).to be_empty
      end

      it "is present if filter does apply" do
        params[:filter] = {abacus_sales_order_key: 1}
        render
        expect(jsonapi_data).to have(1).item
      end
    end
  end
end
