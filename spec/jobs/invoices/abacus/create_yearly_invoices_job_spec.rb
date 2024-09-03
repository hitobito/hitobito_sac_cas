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
      create_person(params: {abacus_subject_key: "129", first_name: "Jane", last_name: "Doe"}),
      create_person(params: {abacus_subject_key: "130", first_name: "Jeffery", last_name: "Doe"}),
      create_person(params: {abacus_subject_key: "131", first_name: "Jack", last_name: "Doe"})
    ]
  end

  let(:unexpected_people) do
    people(:familienmitglied2).update!(abacus_subject_key: "125", data_quality: :error)
    person_1 = create_person(role_created_at: Date.new(invoice_year, 8, 16), params: {abacus_subject_key: "126"})
    person_2 = create_person(params: {abacus_subject_key: "127"})
    person_2.external_invoices.create!(type: ExternalInvoice::SacMembership, year: invoice_year, state: :open)

    # reproduction case where the query returned people which had a different
    # invoice additionally to the SacMembership invoice
    person_3 = create_person(params: {abacus_subject_key: "301"})
    person_3.external_invoices.create!(type: ExternalInvoice::SacMembership, year: invoice_year, state: :open)
    person_3.external_invoices.create!(type: ExternalInvoice::DummyInvoice, year: invoice_year, state: :open)
    [
      people(:familienmitglied2),
      person_1,
      person_2,
      person_3
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

      stub_const("Invoices::Abacus::CreateYearlyInvoicesJob::BATCH_SIZE", 4)
      stub_const("Invoices::Abacus::CreateYearlyInvoicesJob::SLICE_SIZE", 2)
      stub_const("Invoices::Abacus::CreateYearlyInvoicesJob::PARALLEL_THREADS", 2)

      stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
        .with(
          body: /"CustomerId":123.*"CustomerId":124/m,
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
      stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
        .with(
          body: /"CustomerId":130.*"CustomerId":131/m,
          headers: {
            "Authorization" => "Bearer 42",
            "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
          }
        ).to_return(
          status: 202,
          body: batch_response_sales_orders,
          headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
        )
    end

    context "when all calls work but contain some errors" do
      before do
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: /"CustomerId":128.*"CustomerId":129/m,
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
          .to change(ExternalInvoice, :count).by(6)
          .and change { HitobitoLogEntry.where(level: :error).count }.by(1)
          .and change { HitobitoLogEntry.where(level: :info).count }.by(4)
        expect(ExternalInvoice.where(state: :error).count).to eq 1
        expect(HitobitoLogEntry.where(level: :info).last.message).to eq("MV-Jahresinkassolauf: Fortschritt 100%")
      end

      context "when a spurious ExternalInvoice exists" do
        let!(:spurious_invoice) do
          expected_people.first.external_invoices.create!(
            type: ExternalInvoice::SacMembership, state: :draft, year: invoice_year
          )
        end

        it "clears this invoice" do
          expect { subject.perform }
            .to change { ExternalInvoice.where(state: :draft).count }.by(-1)
            .and change { ExternalInvoice.exists?(spurious_invoice.id) }.from(true).to(false)
        end
      end

      context "when role_finish_date is set" do
        let(:role_finish_date) { Date.new(invoice_year, 12, 31) }

        it "Creates the invoices and error logs" do
          expect { subject.perform }
            .to change(ExternalInvoice, :count).by(6)
            .and change { HitobitoLogEntry.where(level: :error).count }.by(1)
            .and change { HitobitoLogEntry.where(level: :info).count }.by(4)
          expect(ExternalInvoice.where(state: :draft).count).to be_zero
          expect(ExternalInvoice.where(state: :error).count).to eq 1
          expect(HitobitoLogEntry.where(level: :info).last.message).to eq("MV-Jahresinkassolauf: Fortschritt 100%")
        end
      end
    end

    context "when a call fails" do
      before do
        allow(Delayed::Worker).to receive(:max_attempts).and_return(2)
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: /"CustomerId":128.*"CustomerId":129/m,
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
        # We get an error in the second slice of the first batch. The 2
        # invoices for the first batch should still be generated, but progress
        # will still be logged as 0%.
        expect { Delayed::Worker.new.run(job_instance) }
          .to change(ExternalInvoice, :count).by(2)
          .and change { HitobitoLogEntry.where(level: :error).count }.by(1)
          .and change { HitobitoLogEntry.where(level: :info).count }.by(1)
        expect(ExternalInvoice.where(state: :draft).count).to be_zero # no left-over drafts
        expect(ExternalInvoice.last.state).to eq("open")
        expect(HitobitoLogEntry.where(level: :info).last.message).to eq("MV-Jahresinkassolauf: Fortschritt 0%")
        expect(HitobitoLogEntry.where(level: :error).last.message).to eq(
          "Mitgliedschaftsrechnungen konnten nicht an Abacus übermittelt werden. Es erfolgt ein weiterer Versuch."
        )

        # retry job to trigger failure: We get an error on the first slice of
        # the first batch, but the second slice will still generate 2 invoices.
        expect { Delayed::Worker.new.run(job_instance) }
          .to change(ExternalInvoice, :count).by(2)
          .and change { HitobitoLogEntry.where(level: :info).count }.by(1)
          .and change { HitobitoLogEntry.where(level: :error).count }.by(2)
        expect(HitobitoLogEntry.where(level: :error).last.message).to eq("MV-Jahresinkassolauf abgebrochen")
        expect(ExternalInvoice.where(state: :draft).count).to be_zero
      end
    end
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
