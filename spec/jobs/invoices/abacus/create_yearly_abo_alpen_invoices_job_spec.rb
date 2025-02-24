# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::Abacus::CreateYearlyAboAlpenInvoicesJob do
  let(:subject) { described_class.new }
  let(:group) { groups(:abo_die_alpen) }
  let(:exception) { StandardError.new("Something went wrong") }

  let!(:abonnent) { people(:abonnent) }
  let!(:abonnent_role) { roles(:abonnent_alpen) }

  let!(:abonnent_2) { Fabricate(:person, abacus_subject_key: "124", country: "CH") }
  let!(:abonnent_role_2) { create_role(abonnent_2) }

  let!(:abonnent_3) { Fabricate(:person, abacus_subject_key: "125", country: "DE", zip_code: "12345") }
  let!(:abonnent_role_3) { create_role(abonnent_3) }

  let!(:abonnent_4) { Fabricate(:person, abacus_subject_key: "126", country: "CH") }
  let!(:abonnent_role_4) { create_role(abonnent_4) }

  let!(:abonnent_5) { Fabricate(:person, abacus_subject_key: "127", country: "CH", language: "fr") }
  let!(:abonnent_role_5) { create_role(abonnent_5) }

  let!(:abonnent_6) { Fabricate(:person, abacus_subject_key: "128", country: "CH") }
  let!(:abonnent_role_6) { create_role(abonnent_6) }

  def create_role(person)
    Fabricate(:role, type: Group::AboMagazin::Abonnent.sti_name,
      person: person,
      group: group,
      start_on: 10.days.ago,
      end_on: 50.days.from_now)
  end

  before do
    Group.root.update!(abo_alpen_fee: 60, abo_alpen_postage_abroad: 16)
    abonnent.update_columns(abacus_subject_key: "123", country: "CH")
    abonnent_role.update_column(:end_on, 50.days.from_now)
  end

  describe "#error" do
    it "creates log entry when job crashes" do
      expect { subject.error(subject, exception) }.to change { HitobitoLogEntry.where(level: :error).count }.by(1)

      expect(HitobitoLogEntry.last.message).to eq "Jahresrechnungen Abo Magazin Die Alpen konnten nicht an Abacus übermittelt werden. " \
              "Es erfolgt ein weiterer Versuch."
    end
  end

  describe "#failure" do
    it "creates log entry when job fails" do
      expect { subject.failure(subject) }.to change { HitobitoLogEntry.where(level: :error).count }.by(1)

      expect(HitobitoLogEntry.last.message).to eq "Rollierender Inkassolauf Abo Magazin Die Alpen abgebrochen."
    end
  end

  describe "#active_abonnenten" do
    it "includes every abonnent role where role end in next 62 days" do
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role, abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]
    end

    it "does not include abonnent where role ends in more than 62 days" do
      abonnent_role.update_column(:end_on, 70.days.from_now)
      expect(subject.send(:active_abonnenten)).not_to include(abonnent_role)
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]
    end

    it "does not include roles when role is terminated" do
      abonnent_role.update_column(:terminated, true)
      expect(subject.send(:active_abonnenten)).not_to include(abonnent_role)
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]
    end

    it "does not include roles where person does not have a abacus subject key" do
      abonnent.update_column(:abacus_subject_key, nil)
      expect(subject.send(:active_abonnenten)).not_to include(abonnent_role)
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]
    end

    it "does not include roles with person who already has external invoice abo magazin in this year" do
      ExternalInvoice::AboMagazin.create!(person: abonnent, year: (abonnent_role.end_on + 1.day).year)
      expect(subject.send(:active_abonnenten)).not_to include(abonnent_role)
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]
    end

    it "does include roles with person who already has external invoice but not in this year" do
      ExternalInvoice::AboMagazin.create!(person: abonnent, year: 3.years.ago.year)
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role, abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]
    end

    it "only checks for external invoice with abo magazin type" do
      ExternalInvoice::AboMagazin.create!(person: abonnent, year: 1.year.ago.year)
      ExternalInvoice::SacMembership.create!(person: abonnent, year: (abonnent_role.end_on + 1.day).year)
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role, abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]

      # add abo magazin invoice for this year, now abonnent should not be included anymore
      ExternalInvoice::AboMagazin.create!(person: abonnent, year: (abonnent_role.end_on + 1.day).year)
      expect(subject.send(:active_abonnenten)).not_to include(abonnent_role)
      expect(subject.send(:active_abonnenten)).to match_array [abonnent_role_2, abonnent_role_3, abonnent_role_4, abonnent_role_5, abonnent_role_6]
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
      Invoices::Abacus::Config.instance_variable_set(:@config, {host: host, mandant: mandant}.stringify_keys)
      allow(Invoices::Abacus::SalesOrderInterface).to receive(:new).and_return(sales_order_interface)
      allow(abacus_client).to receive(:token).and_return("42")
      allow(abacus_client).to receive(:generate_batch_boundary).and_return("batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649")

      stub_const("Invoices::Abacus::CreateYearlyAboAlpenInvoicesJob::SLICE_SIZE", 2)

      stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
        .with(
          body: /
            "CustomerId":123.*
            "OrderDate":"#{Date.current}".*
            "DeliveryDate":"#{Date.current + 2.days}".*
            "InvoiceDate":"#{Date.current + 2.days}".*
            "InvoiceValueDate":"#{abonnent_role.end_on + 1.day}".*
            "TotalAmount":60.0.*
            "Language":"de".*
            "CustomerId":124.*
            "OrderDate":"#{Date.current}".*
            "DeliveryDate":"#{Date.current + 2.days}".*
            "InvoiceDate":"#{Date.current + 2.days}".*
            "InvoiceValueDate":"#{abonnent_role_2.end_on + 1.day}".*
            "TotalAmount":60.0.*
            "Language":"de".*
            "DocumentCodeInvoice":"RA".*
            "ProcessFlowNumber":4
          /xm,
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
          body: /
            "CustomerId":125.*
            "OrderDate":"#{Date.current}".*
            "DeliveryDate":"#{Date.current + 2.days}".*
            "InvoiceDate":"#{Date.current + 2.days}".*
            "InvoiceValueDate":"#{abonnent_role_3.end_on + 1.day}".*
            "TotalAmount":76.0.* # expect postage costs
            "Language":"de".*
            "CustomerId":126.*
            "OrderDate":"#{Date.current}".*
            "DeliveryDate":"#{Date.current + 2.days}".*
            "InvoiceDate":"#{Date.current + 2.days}".*
            "InvoiceValueDate":"#{abonnent_role_4.end_on + 1.day}".*
            "TotalAmount":60.0.*
            "Language":"de".*
            "DocumentCodeInvoice":"RA".*
            "ProcessFlowNumber":4
          /xm,
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

    def expect_external_invoice_values_for(abonnent, abonnent_role)
      external_invoice = abonnent.external_invoices.first

      expect(external_invoice.person_id).to eq abonnent.id
      expect(external_invoice.state).to eq "open"
      expect(external_invoice.issued_at).to eq abonnent_role.end_on + 1.day
      expect(external_invoice.sent_at).to eq Time.zone.today + 2.days
      expect(external_invoice.total).to eq abonnent.living_abroad? ? 76 : 60
      expect(external_invoice.link).to eq abonnent_role.group
      expect(external_invoice.year).to eq (abonnent_role.end_on + 1.day).year
    end

    context "when all calls are successful" do
      before do
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: /
              "CustomerId":127.*
              "OrderDate":"#{Date.current}".*
              "DeliveryDate":"#{Date.current + 2.days}".*
              "InvoiceDate":"#{Date.current + 2.days}".*
              "InvoiceValueDate":"#{abonnent_role.end_on + 1.day}".*
              "TotalAmount":60.0.*
              "Language":"fr".* # expect french
              "CustomerId":128.*
              "OrderDate":"#{Date.current}".*
              "DeliveryDate":"#{Date.current + 2.days}".*
              "InvoiceDate":"#{Date.current + 2.days}".*
              "InvoiceValueDate":"#{abonnent_role_2.end_on + 1.day}".*
              "TotalAmount":60.0.*
              "Language":"de".*
              "DocumentCodeInvoice":"RA".*
              "ProcessFlowNumber":4
            /xm,
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

      it "reschedules to tomorrow at 02:18am" do
        subject.perform

        expect(subject.delayed_jobs.last.run_at).to eq(Time.zone.tomorrow
                                                           .at_beginning_of_day
                                                           .change(hour: 2, minute: 18)
                                                           .in_time_zone)
      end

      it "Creates the invoices" do
        expect { subject.perform }
          .to change(ExternalInvoice, :count).by(6)

        expect_external_invoice_values_for(abonnent, abonnent_role)
        expect_external_invoice_values_for(abonnent_2, abonnent_role_2)
        expect_external_invoice_values_for(abonnent_3, abonnent_role_3)
        expect_external_invoice_values_for(abonnent_4, abonnent_role_4)
        expect_external_invoice_values_for(abonnent_5, abonnent_role_5)
        expect_external_invoice_values_for(abonnent_6, abonnent_role_6)
      end
    end

    context "when all calls work but contain some errors" do
      before do
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: /
              "CustomerId":127.*
              "OrderDate":"#{Date.current}".*
              "DeliveryDate":"#{Date.current + 2.days}".*
              "InvoiceDate":"#{Date.current + 2.days}".*
              "InvoiceValueDate":"#{abonnent_role.end_on + 1.day}".*
              "TotalAmount":60.0.*
              "Language":"fr".* # expect french
              "CustomerId":128.*
              "OrderDate":"#{Date.current}".*
              "DeliveryDate":"#{Date.current + 2.days}".*
              "InvoiceDate":"#{Date.current + 2.days}".*
              "InvoiceValueDate":"#{abonnent_role_2.end_on + 1.day}".*
              "TotalAmount":60.0.*
              "Language":"de".*
              "DocumentCodeInvoice":"RA".*
              "ProcessFlowNumber":4
            /xm,
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
        expect(ExternalInvoice.where(state: :error).count).to eq 1
      end
    end

    context "when a call fails" do
      before do
        allow_any_instance_of(Delayed::Worker).to receive(:max_attempts).and_return(2)
        stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
          .with(
            body: /
              "CustomerId":127.*
              "OrderDate":"#{Date.current}".*
              "DeliveryDate":"#{Date.current + 2.days}".*
              "InvoiceDate":"#{Date.current + 2.days}".*
              "InvoiceValueDate":"#{abonnent_role.end_on + 1.day}".*
              "TotalAmount":60.0.*
              "Language":"fr".* # expect french
              "CustomerId":128.*
              "OrderDate":"#{Date.current}".*
              "DeliveryDate":"#{Date.current + 2.days}".*
              "InvoiceDate":"#{Date.current + 2.days}".*
              "InvoiceValueDate":"#{abonnent_role_2.end_on + 1.day}".*
              "TotalAmount":60.0.*
              "Language":"de".*
              "DocumentCodeInvoice":"RA".*
              "ProcessFlowNumber":4
            /xm,
            headers: {
              "Authorization" => "Bearer 42",
              "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
            }
          )
          .to_return(
            status: 500,
            body: ""
          )
      end

      it "Creates the invoices and error logs for failed invoices" do
        expect { Delayed::Worker.new.run(job_instance) }
          .to change(ExternalInvoice, :count).by(4)
          .and change { HitobitoLogEntry.where(level: :error).count }.by(1)

        expect(HitobitoLogEntry.where(level: :error).last.message).to eq(
          "Jahresrechnungen Abo Magazin Die Alpen konnten nicht an Abacus übermittelt werden. Es erfolgt ein weiterer Versuch."
        )
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
      {"error":{"code":null,"message":"Ungültiger Eingabewert: '154'. (Auftragkopf - Kunden-Nr.)"}}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end
end
