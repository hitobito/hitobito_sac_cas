# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Invoices::Abacus::SalesOrder do

  let(:person) { people(:mitglied) }
  let(:group) { groups(:root) }
  let(:invoice) do
    Invoice.create!(
      recipient: person,
      issued_at: today,
      sent_at: today,
      title: 'MV Rechnung',
      group: group,
      invoice_kind: :membership
    )
  end
  let(:host) { 'https://abacus.example.com' }
  let(:mandant) { 1234 }
  let(:today) { Time.zone.today }
  let(:today_string) { today.strftime('%Y-%m-%d') }

  subject { described_class.new(invoice) }

  before do
    person.abacus_subject_key = 7

    Invoices::Abacus::Config.instance_variable_set(:@config, {host: host, mandant: mandant}.stringify_keys)

    stub_login_requests
  end

  it 'creates sales order in abacus' do
    positions = [
      Invoices::Abacus::InvoicePosition.new(
        name: 'Abo Die Alpen',
        count: 1, amount: 40,
        article_number: 234,
        grouping: 'Beitrag Zentralverband'
        ),
      Invoices::Abacus::InvoicePosition.new(
        name: 'Sektionsbeitrag',
        count: 1, amount: 79,
        article_number: 236,
        other_creditor_id: groups(:bluemlisalp).id,
        grouping: 'Sektionsbeitrag SAC Bluemlisalp'
        ),
      Invoices::Abacus::InvoicePosition.new(
        name: 'Beitrag Zentralverband',
        count: 1,
        amount: 0,
        article_number: 237,
        other_debitor_id: groups(:bluemlisalp).id,
        other_debitor_amount: 20,
        grouping: 'Beitrag Zentralverband'
        )
    ]

    stub_create_sales_order_request
    stub_create_position_request(positions.first, 1,
      { "UserField1": 'Beitrag Zentralverband' })
    stub_create_position_request(positions.second, 2,
      { "UserField1": 'Sektionsbeitrag SAC Bluemlisalp', "UserField2": groups(:bluemlisalp).id })
    stub_create_position_request(positions.third, 3,
      { "UserField1": 'Beitrag Zentralverband', "UserField2": groups(:bluemlisalp).id, "UserField3": 20.0 })
    stub_trigger_sales_order_request

    subject.create(positions)

    expect(invoice.abacus_sales_order_key).to eq(19)
  end

  def stub_login_requests
    stub_request(:get, "#{host}/.well-known/openid-configuration")
      .to_return(status: 200, body: { token_endpoint: "#{host}/oauth/oauth2/v1/token" }.to_json )

    stub_request(:post, "#{host}/oauth/oauth2/v1/token")
      .with(
        body: {"grant_type"=>"client_credentials"},
        headers: {
        'Authorization'=>'Basic Og==',
        'Content-Type'=>'application/x-www-form-urlencoded',
        })
      .to_return(status: 200, body: { access_token: "eyJhbGciOi...", token_type:"Bearer", expires_in: 600 }.to_json)
  end

  def stub_create_sales_order_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrders")
      .with(
        body: "{\"CustomerId\":7,\"OrderDate\":\"#{today_string}\",\"DeliveryDate\":\"#{today_string}\"," \
              "\"TotalAmount\":0.0,\"DocumentCodeInvoice\":\"R\",\"Language\":\"de\",\"UserFields\":" \
              "{\"UserField1\":\"#{invoice.id}\",\"UserField2\":\"hitobito\",\"UserField3\":true}}",
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(
        status: 200,
        body: "{\"SalesOrderId\":19,\"SalesOrderBacklogId\":0,\"CustomerId\":7,\"OrderDate\":\"#{today_string}\"," \
              "\"DeliveryDate\":\"#{today_string}\",\"TotalAmount\":0.0,\"UserFields\":" \
              "{\"UserField1\":#{invoice.id},\"UserField2\":\"hitobito\"}}")
  end

  def stub_trigger_sales_order_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrders(SalesOrderId=19,SalesOrderBacklogId=0)/ch.abacus.orde.TriggerSalesOrderNextStep").
    with(
      body: "{\"TypeOfPrinting\":\"AccToSequentialControl\"}",
      headers: { 'Authorization'=>'Bearer eyJhbGciOi...' }
    ).
    to_return(status: 200, body: "{}")
  end

  def stub_create_position_request(item, index, userfields)
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrderPositions")
    .with(
      body: {
        "SalesOrderId": 19,
        "SalesOrderBacklogId": 0,
        "PositionNumber": index,
        "Type": "Product",
        "Pricing": {"PriceAfterFinding": item.amount.to_f},
        "Quantity": {"Ordered": 1, "Charged": 1, "Delivered": 1},
        "Product": {"Description": item.name, "ProductNumber": item.article_number.to_s},
        "Accounts": {},
        "UserFields": userfields }.to_json,
      headers: { 'Authorization'=>'Bearer eyJhbGciOi...'})
    .to_return(status: 200, body: "{}")
  end


end
