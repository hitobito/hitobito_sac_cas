# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::SalesOrderInterface do
  let(:person) { people(:mitglied) }
  let(:group) { groups(:root) }
  let(:invoice) do
    Invoice.create!(
      recipient: person,
      issued_at: today,
      sent_at: today,
      title: "MV Rechnung",
      group: group,
      invoice_kind: :membership
    )
  end
  let(:host) { "https://abacus.example.com" }
  let(:mandant) { 1234 }
  let(:today) { Time.zone.today }
  let(:today_string) { today.strftime("%Y-%m-%d") }
  let(:sales_order) { Invoices::Abacus::SalesOrder.new(invoice, positions, additional_user_fields) }
  let(:interface) { described_class.new }

  before do
    person.abacus_subject_key = 7

    Invoices::Abacus::Config.instance_variable_set(:@config, {host: host, mandant: mandant}.stringify_keys)

    stub_login_requests
  end

  it "creates sales order in abacus" do
    positions = [
      Invoices::Abacus::InvoicePosition.new(
        name: "Abo Die Alpen",
        count: 1, amount: 40,
        article_number: 234,
        grouping: "Beitrag Zentralverband"
      ),
      Invoices::Abacus::InvoicePosition.new(
        name: "Sektionsbeitrag",
        count: 1, amount: 79,
        article_number: 236,
        other_creditor_id: groups(:bluemlisalp).id,
        grouping: "Sektionsbeitrag SAC Bluemlisalp"
      ),
      Invoices::Abacus::InvoicePosition.new(
        name: "Beitrag Zentralverband",
        count: 1,
        amount: 0,
        article_number: 237,
        other_debitor_id: groups(:bluemlisalp).id,
        other_debitor_amount: 20,
        grouping: "Beitrag Zentralverband"
      )
    ]
    sales_order = Invoices::Abacus::SalesOrder.new(invoice, positions)

    stub_create_sales_order_request
    stub_trigger_sales_order_request

    interface.create(sales_order)

    expect(invoice.abacus_sales_order_key).to eq(19)
  end

  def stub_login_requests
    stub_request(:get, "#{host}/.well-known/openid-configuration")
      .to_return(status: 200, body: {token_endpoint: "#{host}/oauth/oauth2/v1/token"}.to_json)

    stub_request(:post, "#{host}/oauth/oauth2/v1/token")
      .with(
        body: {"grant_type" => "client_credentials"},
        headers: {
          "Authorization" => "Basic Og==",
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      )
      .to_return(status: 200, body: {access_token: "eyJhbGciOi...", token_type: "Bearer", expires_in: 600}.to_json)
  end

  def stub_create_sales_order_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrders")
      .with(
        body: "{\"CustomerId\":7,\"OrderDate\":\"#{today_string}\",\"DeliveryDate\":\"#{today_string}\"," \
              "\"TotalAmount\":0.0,\"DocumentCodeInvoice\":\"R\",\"Language\":\"de\",\"UserFields\":" \
              "{\"UserField1\":\"#{invoice.id}\",\"UserField2\":\"hitobito\",\"UserField3\":true}," \
              "\"Positions\":[{\"PositionNumber\":1,\"Type\":\"Product\",\"Pricing\":{\"PriceAfterFinding\":40.0},\"Quantity\":{\"Ordered\":1,\"Charged\":1,\"Delivered\":1}," \
              "\"Product\":{\"Description\":\"Abo Die Alpen\",\"ProductNumber\":\"234\"},\"Accounts\":{}," \
              "\"UserFields\":{\"UserField1\":\"Beitrag Zentralverband\"}}," \
              "{\"PositionNumber\":2,\"Type\":\"Product\",\"Pricing\":{\"PriceAfterFinding\":79.0},\"Quantity\":{\"Ordered\":1,\"Charged\":1,\"Delivered\":1}," \
              "\"Product\":{\"Description\":\"Sektionsbeitrag\",\"ProductNumber\":\"236\"},\"Accounts\":{}," \
              "\"UserFields\":{\"UserField1\":\"Sektionsbeitrag SAC Bluemlisalp\",\"UserField2\":#{groups(:bluemlisalp).id}}}," \
              "{\"PositionNumber\":3,\"Type\":\"Product\",\"Pricing\":{\"PriceAfterFinding\":0.0},\"Quantity\":{\"Ordered\":1,\"Charged\":1,\"Delivered\":1}," \
              "\"Product\":{\"Description\":\"Beitrag Zentralverband\",\"ProductNumber\":\"237\"},\"Accounts\":{}," \
              "\"UserFields\":{\"UserField1\":\"Beitrag Zentralverband\",\"UserField2\":#{groups(:bluemlisalp).id},\"UserField3\":20.0}}]}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(
        status: 200,
        body: "{\"SalesOrderId\":19,\"SalesOrderBacklogId\":0,\"CustomerId\":7,\"OrderDate\":\"#{today_string}\"," \
              "\"DeliveryDate\":\"#{today_string}\",\"TotalAmount\":0.0,\"UserFields\":" \
              "{\"UserField1\":#{invoice.id},\"UserField2\":\"hitobito\"}}"
      )
  end

  def stub_trigger_sales_order_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrders(SalesOrderId=19,SalesOrderBacklogId=0)/ch.abacus.orde.TriggerSalesOrderNextStep")
      .with(
        body: "{\"TypeOfPrinting\":\"AccToSequentialControl\"}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{}")
  end
end
