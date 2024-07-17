# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::MembershipInvoiceBatcher do
  let(:sac) { Group.root }
  let(:date) { Date.new(2023, 1, 1) }
  let(:people) { Person.with_membership_years("people.*", date).joins(:roles).where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name}).order_by_name }
  let(:abacus_client) { Invoices::Abacus::Client.new }
  let(:host) { "https://abacus.example.com" }
  let(:mandant) { 1234 }
  let(:today) { Time.zone.today.strftime("%Y-%m-%d") }
  let(:dummy_invoice) do
    ExternalInvoice::SacMembership.create!(
      person: people.first,
      issued_at: today,
      sent_at: today
    )
  end
  let(:next_invoice_id) { dummy_invoice.id + 1 }

  subject { described_class.new(date, client: abacus_client) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
    Role.update_all(delete_on: date.end_of_year)
    Person.update_all(zip_code: 3600, town: "Thun")

    Invoices::Abacus::Config.instance_variable_set(:@config, {host: host, mandant: mandant}.stringify_keys)
    allow(abacus_client).to receive(:token).and_return("42")
    allow(abacus_client).to receive(:generate_batch_boundary).and_return("batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649")
  end

  it "creates people in batch" do
    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: batch_body_people,
        headers: {
          "Authorization" => "Bearer 42",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: batch_response_people,
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )

    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: batch_body_subject_assocs,
        headers: {
          "Authorization" => "Bearer 42",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: "",
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )

    subject.create_people(people)
    expect(people.map(&:abacus_subject_key).compact.uniq.size).to eq(people.size)
  end

  it "creates invoices in batch" do
    people.each_with_index { |p, i| p.abacus_subject_key = i + 10 }

    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: batch_body_sales_orders,
        headers: {
          "Authorization" => "Bearer 42",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: batch_response_sales_orders,
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )

    expect do
      subject.create_invoices(people)
    end.to change { ExternalInvoice.count }.by(2)

    invoice = ExternalInvoice.last
    expect(invoice.abacus_sales_order_key).to eq(45)
    expect(invoice.issued_at).to eq(date)
    expect(invoice.sent_at).to eq(date)
    expect(invoice.to_s).to eq("Mitgliedschaftsrechnung 2023")
    expect(invoice.total).to eq(267.0)
    expect(invoice.class).to eq(ExternalInvoice::SacMembership)
    expect(invoice.year).to eq(2023)
    expect(invoice.person).to eq(people.last)
  end

  def batch_body_people
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Subjects HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Hillary","FirstName":"Edmund","Language":"de","SalutationId":2,"Id":600001}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Subjects HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Frieda","Language":"de","SalutationId":2,"Id":600003}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Subjects HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Nima","Language":"de","SalutationId":2,"Id":600004}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Subjects HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Tenzing","Language":"de","SalutationId":2,"Id":600002}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
  end

  def batch_response_people
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Hillary","FirstName":"Edmund","Language":"de","SalutationId":2,"Id":600001}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Frieda","Language":"de","SalutationId":2,"Id":600003}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Nima","Language":"de","SalutationId":2,"Id":600004}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Tenzing","Language":"de","SalutationId":2,"Id":600002}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end

  def batch_body_subject_assocs
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600001,"Street":"","HouseNumber":"","PostCode":"3600","City":"Thun","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Communications HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600001,"Type":"EMail","Value":"e.hillary@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600001}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600003,"Street":"","HouseNumber":"","PostCode":"3600","City":"Thun","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Communications HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600003,"Type":"EMail","Value":"f.norgay@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600003}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600004,"Street":"","HouseNumber":"","PostCode":"3600","City":"Thun","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Communications HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600004,"Type":"EMail","Value":"n.norgay@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600004}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002,"Street":"","HouseNumber":"","PostCode":"3600","City":"Thun","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Communications HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002,"Type":"EMail","Value":"t.norgay@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
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
      {"CustomerId":10,"OrderDate":"2023-01-01","DeliveryDate":"2023-01-01","TotalAmount":183.0,"DocumentCodeInvoice":"R","Language":"de","UserFields":{"UserField1":"#{next_invoice_id}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"600001;Hillary;Edmund;#{people[0].membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":40.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":42.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":#{groups(:bluemlisalp).id},"UserField4":"Einzelmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":56.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Matterhorn","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Matterhorn","UserField2":#{groups(:matterhorn).id},"UserField4":"Einzelmitglied"}}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST SalesOrders HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"CustomerId":13,"OrderDate":"2023-01-01","DeliveryDate":"2023-01-01","TotalAmount":267.0,"DocumentCodeInvoice":"R","Language":"de","UserFields":{"UserField1":"#{next_invoice_id + 1}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"600002;Norgay;Tenzing;#{people[3].membership_verify_token}","UserField12":"600003;Norgay;Frieda;#{people[1].membership_verify_token}","UserField13":"600004;Norgay;Nima;#{people[2].membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":50.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":84.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":#{groups(:bluemlisalp).id},"UserField4":"Familienmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":88.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Matterhorn","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Matterhorn","UserField2":#{groups(:matterhorn).id},"UserField4":"Familienmitglied"}}]}\r
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
