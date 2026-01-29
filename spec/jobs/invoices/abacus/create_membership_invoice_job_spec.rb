# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::Abacus::CreateMembershipInvoiceJob do
  let(:person) { people(:mitglied) }
  let(:section) { groups(:bluemlisalp) }
  let(:now) { Time.zone.local(2024, 8, 24, 1) }

  let(:external_invoice) {
    Fabricate(:external_invoice, person: person,
      link: section,
      state: :draft,
      issued_at: reference_date,
      sent_at: reference_date,
      year: reference_date.year,
      total: 0,
      type: "ExternalInvoice::SacMembership")
  }
  let(:reference_date) { now }
  let(:client) { instance_double(Invoices::Abacus::Client) }

  before { travel_to(now) }

  let(:discount) { nil }
  let(:new_entry) { false }
  let(:dont_send) { false }
  let(:dispatch_type) { nil }
  let(:manual_positions) { {} }

  subject(:job) do
    described_class.new(
      external_invoice,
      reference_date,
      discount: discount,
      new_entry: new_entry,
      dont_send: dont_send,
      dispatch_type: dispatch_type,
      manual_positions: manual_positions
    )
  end

  before { allow(job).to receive(:client).and_return(client) }

  it "transmits subject, updates invoice total and transmit_sales_order" do
    order = satisfy do |o|
      o.full_attrs[:process_flow_number] == 3 &&
        o.full_attrs[:user_fields][:user_field3] == "Mail"
    end
    allow_any_instance_of(Invoices::Abacus::SubjectInterface)
      .to receive(:transmit).and_return(true)
    allow_any_instance_of(Invoices::Abacus::SalesOrderInterface)
      .to receive(:create).with(order)
    expect do
      job.perform
    end.to change { external_invoice.reload.total }
  end

  context "without send_invoice" do
    let(:dont_send) { true }

    it "uses special process flow number if invoice should not be sent" do
      order = satisfy { |o| o.full_attrs[:process_flow_number] == 6 }
      allow_any_instance_of(Invoices::Abacus::SubjectInterface)
        .to receive(:transmit).and_return(true)
      allow_any_instance_of(Invoices::Abacus::SalesOrderInterface)
        .to receive(:create).with(order)
      job.perform
    end
  end

  context "with manual_positions" do
    let(:manual_positions) do
      {
        sac_fee: 100,
        sac_entry_fee: 20,
        hut_solidarity_fee: 30,
        sac_magazine: 25,
        sac_magazine_postage_abroad: 35,
        section_entry_fee: 50,
        section_fees: [
          {section_id: 30, fee: 40},
          {section_id: 31, fee: 50}
        ]
      }
    end

    it "uses ManualPositionGenerator, transmits subject, updates invoice total and transmit_sales_order" do
      order = satisfy do |o|
        o.full_attrs[:process_flow_number] == 3 &&
          o.full_attrs[:user_fields][:user_field3] == "Mail"
      end

      expect(job.manual_positions.keys.map(&:class).uniq).to eq([String])
      expect(job.manual_positions["section_fees"].flat_map(&:keys).map(&:class).uniq).to eq([String])

      expect(Invoices::SacMemberships::ManualPositionGenerator)
        .to receive(:new).with(anything, manual_positions)
        .and_call_original
      allow_any_instance_of(Invoices::Abacus::SubjectInterface)
        .to receive(:transmit).and_return(true)
      allow_any_instance_of(Invoices::Abacus::SalesOrderInterface)
        .to receive(:create).with(order)
      expect do
        job.perform
      end.to change { external_invoice.reload.total }
    end
  end

  context "with custom dispatch type" do
    let(:dispatch_type) { :print }

    it "is used in user field" do
      order = satisfy do |o|
        o.full_attrs[:process_flow_number] == 3 &&
          o.full_attrs[:user_fields][:user_field3] == "Letter"
      end
      allow_any_instance_of(Invoices::Abacus::SubjectInterface)
        .to receive(:transmit).and_return(true)
      allow_any_instance_of(Invoices::Abacus::SalesOrderInterface)
        .to receive(:create).with(order)

      job.perform
    end
  end

  context "invoice errors" do
    context "without memberships" do
      let(:log_entry) { HitobitoLogEntry.last }
      let(:reference_date) { roles(:mitglied).end_on + 1.day }

      it "creates log, updates invoice state to error" do
        expect do
          job.perform
        end.to change { HitobitoLogEntry.count }.by(1)
          .and change { external_invoice.reload.state }.to("error")
        expect(log_entry.level).to eq "error"
        expect(log_entry.category).to eq "rechnungen"
        expect(log_entry.message).to eq "Für die gewünschte Sektion besteht am gewählten Datum " \
          "keine Mitgliedschaft. Es wurde entsprechend keine Rechnung erstellt."
        expect(log_entry.subject).to eq external_invoice
      end
    end

    context "for non sac_family_main_person person" do
      let(:log_entry) { HitobitoLogEntry.last }
      let(:person) { people(:familienmitglied2) }

      it "creates log, updates invoice state to error" do
        expect do
          job.perform
        end.to change { HitobitoLogEntry.count }.by(1)
          .and change { external_invoice.reload.state }.to("error")
        expect(log_entry.level).to eq "error"
        expect(log_entry.category).to eq "rechnungen"
        expect(log_entry.message).to eq "Für die gewünschte Person und Sektion fallen keine " \
         "Mitgliedschaftsgebühren an, oder diese sind bereits über andere Rechnungen abgedeckt."
        expect(log_entry.subject).to eq external_invoice
      end
    end
  end

  context "processing errors" do
    let(:log_entry) { HitobitoLogEntry.last }

    it "raises without creating log or updating invoice state" do
      expect do
        allow_any_instance_of(Invoices::Abacus::SubjectInterface)
          .to receive(:transmit).and_raise("ouch")
        job.perform
      end.to raise_error(StandardError, "ouch")
        .and not_change { HitobitoLogEntry.count }
        .and not_change { external_invoice.reload.state }
    end

    context "when running via worker" do
      it "creates log entry with error message" do
        allow_any_instance_of(Invoices::Abacus::SubjectInterface)
          .to receive(:transmit).and_raise("ouch")

        expect do
          Delayed::Worker.new.run(job.enqueue!)
        end.to change { HitobitoLogEntry.count }.by(1)
          .and not_change { external_invoice.reload.state }
        expect(log_entry.level).to eq "error"
        expect(log_entry.category).to eq "rechnungen"
        expect(log_entry.message).to eq "Probleme beim Erstellen der Rechnung"
        expect(log_entry.payload).to eq "ouch"
        expect(log_entry.subject).to eq external_invoice
      end

      it "updates invoice state to error when all attemps fail" do
        allow_any_instance_of(Invoices::Abacus::SubjectInterface)
          .to receive(:transmit).and_raise("ouch")
        allow(Delayed::Worker).to receive(:max_attempts).and_return(2)
        delayed_job = job.enqueue!
        expect do
          2.times { Delayed::Worker.new.run(delayed_job.reload) }
        end.to change { HitobitoLogEntry.count }.by(2)
          .and change { external_invoice.reload.state }.to("error")
      end
    end

    context "data quality errors" do
      let(:log_entry) { HitobitoLogEntry.last }

      before { person.update!(data_quality: :error) }

      it "creates log, updates invoice state to error" do
        expect { job.perform }.to change { HitobitoLogEntry.count }.by(1)
          .and change { external_invoice.reload.state }.to("error")
        expect(log_entry.level).to eq("error")
        expect(log_entry.category).to eq("rechnungen")
        expect(log_entry.message).to match(/Datenqualitätsprobleme/)
        expect(log_entry.subject).to eq(external_invoice)
      end
    end
  end
end
