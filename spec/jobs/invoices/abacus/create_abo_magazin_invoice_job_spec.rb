# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::Abacus::CreateAboMagazinInvoiceJob do
  let(:person) { people(:mitglied) }
  let(:abo_die_alpen) { groups(:abo_die_alpen) }
  let(:neuanmeldung_abonnent_role) { Fabricate(Group::AboMagazin::Neuanmeldung.sti_name, person: person, group: abo_die_alpen, start_on: 1.day.ago, end_on: 20.days.from_now) }
  let(:now) { Time.zone.now }
  let(:external_invoice) {
    Fabricate(:external_invoice, person: person,
      link: abo_die_alpen,
      state: :draft,
      issued_at: now,
      sent_at: now,
      year: now.year,
      total: 0,
      type: "ExternalInvoice::AboMagazin")
  }
  let(:reference_date) { now }
  let(:client) { instance_double(Invoices::Abacus::Client) }

  subject(:job) { described_class.new(external_invoice, neuanmeldung_abonnent_role.id) }

  before do
    allow(job).to receive(:client).and_return(client)
    Group.root.update!(abo_alpen_fee_article_number: "APG", abo_alpen_fee: 20, abo_alpen_postage_abroad: 6)
  end

  it "transmits subject, updates invoice total and transmit_sales_order" do
    allow_any_instance_of(Invoices::Abacus::SubjectInterface).to receive(:transmit).and_return(true)
    allow_any_instance_of(Invoices::Abacus::SalesOrderInterface).to receive(:create)
    expect(Invoices::Abacus::AboMagazinInvoice).to receive(:new).with(neuanmeldung_abonnent_role, external_invoice.issued_at).and_call_original
    expect do
      job.perform
    end.to change { external_invoice.reload.total }
  end

  context "processing errors" do
    let(:log_entry) { HitobitoLogEntry.last }

    it "raises without creating log or updating invoice state" do
      expect do
        allow_any_instance_of(Invoices::Abacus::SubjectInterface).to receive(:transmit).and_raise("ouch")
        job.perform
      end.to raise_error(StandardError, "ouch")
        .and not_change { HitobitoLogEntry.count }
        .and not_change { external_invoice.reload.state }
    end

    context "when running via worker" do
      it "creates log entry with error message" do
        allow_any_instance_of(Invoices::Abacus::SubjectInterface).to receive(:transmit).and_raise("ouch")
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
        allow_any_instance_of(Invoices::Abacus::SubjectInterface).to receive(:transmit).and_raise("ouch")
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
