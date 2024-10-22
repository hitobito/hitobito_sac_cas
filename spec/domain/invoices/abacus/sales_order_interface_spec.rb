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
    ExternalInvoice::SacMembership.create!(
      person: person,
      issued_at: "2020-01-15",
      sent_at: "2020-01-05"
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

  it "creates sac membership sales order in abacus" do
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
    stub_trigger_sales_order_request(19)

    interface.create(sales_order)

    expect(invoice.abacus_sales_order_key).to eq(19)
  end

  it "creates course participation sales order in abacus" do
    course = Fabricate(:sac_course, kind: event_kinds(:ski_course))
    participation = Fabricate(:event_participation, event: course, person: person, price: 20, price_category: 1)
    invoice = ExternalInvoice::CourseParticipation.create!(
      person: person,
      issued_at: "2020-01-15",
      sent_at: "2020-01-05",
      link: participation
    )
    positions = [
      Invoices::Abacus::InvoicePosition.new(
        name: "Kursname (234)",
        count: 1, amount: 20,
        article_number: 234,
        grouping: "Kursname (234)"
      )
    ]
    sales_order = Invoices::Abacus::SalesOrder.new(invoice, positions)

    stub_create_course_sales_order_request(invoice.id)
    stub_trigger_sales_order_request(20)

    interface.create(sales_order)

    expect(invoice.abacus_sales_order_key).to eq(20)
  end

  it "cancel sales order in abacus" do
    invoice.update!(abacus_sales_order_key: 19)
    sales_order = Invoices::Abacus::SalesOrder.new(invoice)

    stub_update_sales_order_request

    interface.cancel(sales_order)

    expect(invoice.state).to eq("cancelled")
  end

  context "batch" do
    let(:date) { Date.new(2023, 1, 1) }
    let(:context) { Invoices::SacMemberships::Context.new(date) }
    let(:members) do
      context
        .people_with_membership_years
        .where("people.id IN (#{
          Group::SektionsMitglieder::Mitglied.with_inactive.distinct.select(:person_id).to_sql
        })")
        .order_by_name
    end
    let(:dummy_invoice) do
      ExternalInvoice::SacMembership.create!(
        person: members.first,
        issued_at: today,
        sent_at: today
      )
    end
    let(:next_invoice_id) { dummy_invoice.id + 1 }

    before do
      SacMembershipConfig.update_all(valid_from: 2020)
      SacSectionMembershipConfig.update_all(valid_from: 2020)
      Role.update_all(end_on: date.end_of_year)
      Person.update_all(zip_code: 3600, street: nil, housenumber: nil, town: "Thun", country: nil)

      allow(interface.send(:client)).to receive(:generate_batch_boundary).and_return("batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649")
    end

    it "creates invoices in batch" do
      members.each_with_index { |p, i| p.abacus_subject_key = i + 10 }

      stub_batch_create_sales_order_request

      expect do
        membership_invoices = membership_invoices(members)
        sales_orders = create_sales_orders(membership_invoices)
        interface.create_batch(sales_orders)
      end.to change { ExternalInvoice.count }.by(2)

      invoice = ExternalInvoice.last
      expect(invoice.abacus_sales_order_key).to eq(45)
      expect(invoice.issued_at).to eq(date)
      expect(invoice.sent_at).to eq(date)
      expect(invoice.title).to eq("Mitgliedschaftsrechnung 2023")
      expect(invoice.total).to eq(267.0)
      expect(invoice.class).to eq(ExternalInvoice::SacMembership)
      expect(invoice.year).to eq(2023)
      expect(invoice.person).to eq(members.last)
    end

    def membership_invoices(people)
      people.filter_map do |person|
        member = Invoices::SacMemberships::Member.new(person, context)
        if member.stammsektion_role
          invoice = Invoices::Abacus::MembershipInvoice.new(member, member.active_memberships)
          invoice if invoice.invoice?
        end
      end
    end

    def create_sales_orders(membership_invoices)
      membership_invoices.map do |mi|
        invoice = create_invoice(mi)
        Invoices::Abacus::SalesOrder.new(invoice, mi.positions, mi.additional_user_fields)
      end
    end

    def create_invoice(membership_invoice) # rubocop:disable Metrics/MethodLength
      ExternalInvoice::SacMembership.create!(
        person: membership_invoice.member.person,
        year: date.year,
        state: :draft,
        total: membership_invoice.total,
        issued_at: date,
        sent_at: date,
        # also see comment in ExternalInvoice::SacMembership
        link: membership_invoice.member.stammsektion
      )
    end
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
        body: "{\"CustomerId\":7,\"OrderDate\":\"#{today_string}\",\"DeliveryDate\":\"2020-01-05\"," \
              "\"InvoiceDate\":\"2020-01-05\",\"InvoiceValueDate\":\"2020-01-15\"," \
              "\"TotalAmount\":0.0,\"Language\":\"de\",\"DocumentCodeInvoice\":\"R\",\"ProcessFlowNumber\":1,\"UserFields\":" \
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
              "\"DeliveryDate\":\"2020-01-05\",\"InvoiceDate\":\"2020-01-05\",\"InvoiceValueDate\":\"2020-01-15\"," \
              "\"TotalAmount\":0.0,\"UserFields\":" \
              "{\"UserField1\":#{invoice.id},\"UserField2\":\"hitobito\"}}"
      )
  end

  def stub_create_course_sales_order_request(invoice_id)
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrders")
      .with(
        body: "{\"CustomerId\":7,\"OrderDate\":\"#{today_string}\",\"DeliveryDate\":\"2020-01-05\"," \
              "\"InvoiceDate\":\"2020-01-05\",\"InvoiceValueDate\":\"2020-01-15\"," \
              "\"TotalAmount\":0.0,\"Language\":\"de\",\"DocumentCodeInvoice\":\"RK\",\"ProcessFlowNumber\":2,\"UserFields\":" \
              "{\"UserField1\":\"#{invoice_id}\",\"UserField2\":\"hitobito\",\"UserField3\":true}," \
              "\"Positions\":[{\"PositionNumber\":1,\"Type\":\"Product\",\"Pricing\":{\"PriceAfterFinding\":20.0},\"Quantity\":{\"Ordered\":1,\"Charged\":1,\"Delivered\":1}," \
              "\"Product\":{\"Description\":\"Kursname (234)\",\"ProductNumber\":\"234\"},\"Accounts\":{},\"UserFields\":{\"UserField1\":\"Kursname (234)\"}}]}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(
        status: 200,
        body: "{\"SalesOrderId\":20,\"SalesOrderBacklogId\":0,\"CustomerId\":7,\"OrderDate\":\"#{today_string}\"," \
              "\"DeliveryDate\":\"2020-01-05\",\"InvoiceDate\":\"2020-01-05\",\"InvoiceValueDate\":\"2020-01-15\"," \
              "\"TotalAmount\":0.0,\"UserFields\":" \
              "{\"UserField1\":#{invoice_id},\"UserField2\":\"hitobito\"}}"
      )
  end

  def stub_trigger_sales_order_request(id)
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrders(SalesOrderId=#{id},SalesOrderBacklogId=0)/ch.abacus.orde.TriggerSalesOrderNextStep")
      .with(
        body: "{\"TypeOfPrinting\":\"AccToSequentialControl\"}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{}")
  end

  def stub_update_sales_order_request
    stub_request(:patch, "#{host}/api/entity/v1/mandants/#{mandant}/SalesOrders(SalesOrderId=19,SalesOrderBacklogId=0)")
      .with(
        body: "{\"UserFields\":{\"UserField21\":true}}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{}")
  end

  def stub_batch_create_sales_order_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: batch_body_sales_orders,
        headers: {
          "Authorization" => "Bearer eyJhbGciOi...",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: batch_response_sales_orders,
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )
  end

  def batch_body_sales_orders
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST SalesOrders HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"CustomerId":10,"OrderDate":"#{today_string}","DeliveryDate":"2023-01-01","InvoiceDate":"2023-01-01","InvoiceValueDate":"2023-01-01","TotalAmount":183.0,"Language":"de","DocumentCodeInvoice":"R","ProcessFlowNumber":1,"UserFields":{"UserField1":"#{next_invoice_id}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"600001;Hillary;Edmund;#{members[0].membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":40.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":42.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":#{groups(:bluemlisalp).id},"UserField4":"Einzelmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":56.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Matterhorn","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Matterhorn","UserField2":#{groups(:matterhorn).id},"UserField4":"Einzelmitglied"}}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST SalesOrders HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"CustomerId":13,"OrderDate":"#{today_string}","DeliveryDate":"2023-01-01","InvoiceDate":"2023-01-01","InvoiceValueDate":"2023-01-01","TotalAmount":267.0,"Language":"de","DocumentCodeInvoice":"R","ProcessFlowNumber":1,"UserFields":{"UserField1":"#{next_invoice_id + 1}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"600002;Norgay;Tenzing;#{members[3].membership_verify_token}","UserField12":"600003;Norgay;Frieda;#{members[1].membership_verify_token}","UserField13":"600004;Norgay;Nima;#{members[2].membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":50.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":84.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":#{groups(:bluemlisalp).id},"UserField4":"Familienmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":88.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Matterhorn","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Matterhorn","UserField2":#{groups(:matterhorn).id},"UserField4":"Familienmitglied"}}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
  end

  def batch_response_sales_orders
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SalesOrderId":42,"SalesOrderBacklogId":0}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SalesOrderId":45,"SalesOrderBacklogId":0}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end
end
