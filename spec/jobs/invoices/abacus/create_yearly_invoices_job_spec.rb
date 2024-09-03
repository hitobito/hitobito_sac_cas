# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

class ExternalInvoice::DummyInvoice < ExternalInvoice
end

describe Invoices::Abacus::CreateYearlyInvoicesJob do
  let(:params) { {invoice_year:, invoice_date:, send_date:, role_finish_date:} }
  let(:invoice_year) { 2024 }
  let(:invoice_date) { Date.new(2025, 1, 1) }
  let(:send_date) { Date.new(2025, 1, 2) }
  let(:role_finish_date) { nil }
  let(:subject) { described_class.new(**params) }

  let(:expected_people) do
    # People that should show up
    people(:mitglied).update!(abacus_subject_key: "123")
    people(:familienmitglied).update!(abacus_subject_key: "124")
    valid_person = create_person(params: {abacus_subject_key: "128", first_name: "Joe", last_name: "Doe"})
    valid_person.external_invoices.create!(type: ExternalInvoice::DummyInvoice, year: invoice_year, state: :open)
    [
      people(:mitglied),
      people(:familienmitglied),
      valid_person,
      create_person(params: {abacus_subject_key: "129", first_name: "Jane", last_name: "Doe"})
    ]
  end

  let(:unexpected_people) do
    people(:familienmitglied2).update!(abacus_subject_key: "125", data_quality: :error)
    person_1 = create_person(role_created_at: Date.new(invoice_year, 8, 16), params: {abacus_subject_key: "126"})
    person_2 = create_person(params: {abacus_subject_key: "127"})
    person_2.external_invoices.create!(type: ExternalInvoice::SacMembership, year: invoice_year, state: :open)
    [
      people(:familienmitglied2),
      person_1,
      person_2
    ]
  end

  def create_mix_of_people
    expected_people
    unexpected_people
  end

  describe "#enqueue!" do
    it "will create a job and raise if there is already one running" do
      expect { subject.enqueue! }.to change(Delayed::Job, :count).by(1)
      expect { subject.enqueue! }.to raise_error("There is already a job running")
    end
  end

  def create_person(role_created_at: Date.new(invoice_year, 1, 1), params: {})
    group = groups(:bluemlisalp_mitglieder)
    person = Fabricate.create(:person_with_address, **params)
    Fabricate.create(Group::SektionsMitglieder::Mitglied.sti_name, created_at: role_created_at, group:, person:)
    person
  end

  describe "#active_members" do
    context "without any people that have an abacus_subject_key" do
      it "returns an empty array" do
        expect(subject.active_members).to eq []
      end
    end

    context "with a wild mix of people" do
      before do
        create_mix_of_people
      end

      it "returns the correct people" do
        expect(subject.active_members).to match_array(expected_people)
      end
    end
  end

  describe "#perform" do
    let(:host) { "https://abacus.example.com" }
    let(:mandant) { 1234 }
    let(:today) { Time.zone.today.strftime("%Y-%m-%d") }
    let(:dummy_invoice) do
      ExternalInvoice::SacMembership.create!(
        person: people.last,
        issued_at: today,
        sent_at: today,
        state: :open
      )
    end
    let(:next_invoice_id) { dummy_invoice.id + 1 }

    let(:abacus_client) { Invoices::Abacus::Client.new }
    let(:sales_order_interface) { Invoices::Abacus::SalesOrderInterface.new(abacus_client) }
    let(:job_instance) do
      subject.enqueue!
    end

    before do
      create_mix_of_people
      Invoices::Abacus::Config.instance_variable_set(:@config, {host: host, mandant: mandant}.stringify_keys)
      allow(Invoices::Abacus::SalesOrderInterface).to receive(:new).and_return(sales_order_interface)
      allow(abacus_client).to receive(:token).and_return("42")
      allow(abacus_client).to receive(:generate_batch_boundary).and_return("batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649")

      stub_const("Invoices::Abacus::CreateYearlyInvoicesJob::BATCH_SIZE", 2)
      stub_const("Invoices::Abacus::CreateYearlyInvoicesJob::SLICE_SIZE", 2)
      stub_const("Invoices::Abacus::CreateYearlyInvoicesJob::PARALLEL_THREADS", 1)

      stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
        .with(
          body: batch_body_sales_orders_1,
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
    end

    context "when all calls work but contain some errors" do
      before do
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: batch_body_sales_orders_2(next_invoice_id + 2),
            headers: {
              "Authorization" => "Bearer 42",
              "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
            }
          ).to_return(
            status: 202,
            body: batch_response_sales_orders_with_error,
            headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
          )
      end

      it "Creates the invoices and error logs" do
        expect { subject.perform }
          .to change(ExternalInvoice, :count).by(4)
          .and change { HitobitoLogEntry.where(level: :error).count }.by(1)
          .and change { HitobitoLogEntry.where(level: :info).count }.by(4)
        expect(ExternalInvoice.last.state).to eq("error")
        expect(HitobitoLogEntry.where(level: :info).last.message).to eq("MV-Jahresinkassolauf: Fortschritt 100%")
      end

      context "when role_finish_date is set" do
        let(:role_finish_date) { Date.new(invoice_year, 12, 31) }

        it "Creates the invoices and error logs" do
          expect { subject.perform }
            .to change(ExternalInvoice, :count).by(4)
            .and change { HitobitoLogEntry.where(level: :error).count }.by(1)
            .and change { HitobitoLogEntry.where(level: :info).count }.by(4)
          expect(ExternalInvoice.where(state: :draft).count).to be_zero
          expect(ExternalInvoice.last.state).to eq("error")
          expect(HitobitoLogEntry.where(level: :info).last.message).to eq("MV-Jahresinkassolauf: Fortschritt 100%")
        end
      end
    end

    context "when a call fails" do
      before do
        allow(Delayed::Worker).to receive(:max_attempts).and_return(2)
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: batch_body_sales_orders_2(next_invoice_id + 2),
            headers: {
              "Authorization" => "Bearer 42",
              "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
            }
          ).to_return(
            status: 500,
            body: ""
          )
        # To test the retry almost the same request will be done, just with increased invoice_ids
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: batch_body_sales_orders_2(next_invoice_id + 4),
            headers: {
              "Authorization" => "Bearer 42",
              "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
            }
          ).to_return(
            status: 500,
            body: ""
          )
      end

      it "Creates the invoices and error logs" do
        expect(HitobitoLogEntry.where(level: :error).count).to be_zero
        expect { Delayed::Worker.new.run(job_instance) }
          .to change(ExternalInvoice, :count).by(2)
          .and change { HitobitoLogEntry.where(level: :error).count }.by(1)
          .and change { HitobitoLogEntry.where(level: :info).count }.by(2)
        expect(ExternalInvoice.where(state: :draft).count).to be_zero # no left-over drafts
        expect(ExternalInvoice.last.state).to eq("open")
        expect(HitobitoLogEntry.where(level: :info).last.message).to eq("MV-Jahresinkassolauf: Fortschritt 50%")
        expect(HitobitoLogEntry.where(level: :error).last.message).to eq(
          "Mitgliedschaftsrechnungen konnten nicht an Abacus übermittelt werden. Es erfolgt ein weiterer Versuch."
        )

        # retry job to trigger failure
        expect { Delayed::Worker.new.run(job_instance) }
          .to not_change(ExternalInvoice, :count)
          .and change { HitobitoLogEntry.where(level: :info).count }.by(1)
          .and change { HitobitoLogEntry.where(level: :error).count }.by(2)
        expect(HitobitoLogEntry.where(level: :error).last.message).to eq("MV-Jahresinkassolauf abgebrochen")
        expect(ExternalInvoice.where(state: :draft).count).to be_zero
      end
    end
  end

  def batch_body_sales_orders_1
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST SalesOrders HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"CustomerId":123,"OrderDate":"#{invoice_date}","DeliveryDate":"#{send_date}","TotalAmount":183.0,"DocumentCodeInvoice":"R","Language":"de","UserFields":{"UserField1":"#{next_invoice_id}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"600001;Hillary;Edmund;#{expected_people[0].membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":40.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":42.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":578575972,"UserField4":"Einzelmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":56.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Matterhorn","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Matterhorn","UserField2":#{groups(:matterhorn).id},"UserField4":"Einzelmitglied"}}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST SalesOrders HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"CustomerId":124,"OrderDate":"#{invoice_date}","DeliveryDate":"2025-01-02","TotalAmount":267.0,"DocumentCodeInvoice":"R","Language":"de","UserFields":{"UserField1":"#{next_invoice_id + 1}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"600002;Norgay;Tenzing;#{expected_people[1].membership_verify_token}","UserField12":"600003;Norgay;Frieda;#{people(:familienmitglied2).membership_verify_token}","UserField13":"600004;Norgay;Nima;#{people(:familienmitglied_kind).membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":50.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Familienmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":84.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":#{groups(:bluemlisalp).id},"UserField4":"Familienmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":88.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Matterhorn","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Matterhorn","UserField2":#{groups(:matterhorn).id},"UserField4":"Familienmitglied"}}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
  end

  def batch_body_sales_orders_2(invoice_id_start)
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST SalesOrders HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"CustomerId":128,"OrderDate":"#{invoice_date}","DeliveryDate":"2025-01-02","TotalAmount":150.0,"DocumentCodeInvoice":"R","Language":"de","UserFields":{"UserField1":"#{invoice_id_start}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"#{expected_people[2].id};Doe;Joe;#{expected_people[2].membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":40.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":10.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Porto Die Alpen Zentralverband","ProductNumber":"99"},"Accounts":{},"UserFields":{"UserField1":"Porto Die Alpen Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":42.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":578575972,"UserField4":"Einzelmitglied"}},{"PositionNumber":6,"Type":"Product","Pricing":{"PriceAfterFinding":13.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Porto Bulletin SAC Blüemlisalp","ProductNumber":"46"},"Accounts":{},"UserFields":{"UserField1":"Porto Bulletin SAC Blüemlisalp","UserField2":578575972,"UserField4":"Einzelmitglied"}}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST SalesOrders HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"CustomerId":129,"OrderDate":"#{invoice_date}","DeliveryDate":"2025-01-02","TotalAmount":150.0,"DocumentCodeInvoice":"R","Language":"de","UserFields":{"UserField1":"#{invoice_id_start + 1}","UserField2":"hitobito","UserField3":true,"UserField4":1.0,"UserField11":"#{expected_people[3].id};Doe;Jane;#{expected_people[3].membership_verify_token}"},"Positions":[{"PositionNumber":1,"Type":"Product","Pricing":{"PriceAfterFinding":40.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag Zentralverband","ProductNumber":"42"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":2,"Type":"Product","Pricing":{"PriceAfterFinding":20.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Hütten Solidaritätsbeitrag","ProductNumber":"44"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":3,"Type":"Product","Pricing":{"PriceAfterFinding":25.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Alpengebühren","ProductNumber":"45"},"Accounts":{},"UserFields":{"UserField1":"Beitrag Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":4,"Type":"Product","Pricing":{"PriceAfterFinding":10.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Porto Die Alpen Zentralverband","ProductNumber":"99"},"Accounts":{},"UserFields":{"UserField1":"Porto Die Alpen Zentralverband","UserField4":"Einzelmitglied"}},{"PositionNumber":5,"Type":"Product","Pricing":{"PriceAfterFinding":42.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Beitrag SAC Blüemlisalp","ProductNumber":"98"},"Accounts":{},"UserFields":{"UserField1":"Beitrag SAC Blüemlisalp","UserField2":578575972,"UserField4":"Einzelmitglied"}},{"PositionNumber":6,"Type":"Product","Pricing":{"PriceAfterFinding":13.0},"Quantity":{"Ordered":1,"Charged":1,"Delivered":1},"Product":{"Description":"Porto Bulletin SAC Blüemlisalp","ProductNumber":"46"},"Accounts":{},"UserFields":{"UserField1":"Porto Bulletin SAC Blüemlisalp","UserField2":578575972,"UserField4":"Einzelmitglied"}}]}\r
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
      {"SalesOrderId":48,"SalesOrderBacklogId":0}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end

  def batch_response_sales_orders_with_error
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
      HTTP/1.1 400 Bad Request\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"error":{"code":null,"message":"Ungültiger Eingabewert: '124'. (Auftragkopf - Kunden-Nr.)"}}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end
end
