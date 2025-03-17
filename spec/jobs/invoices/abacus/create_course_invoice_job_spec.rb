# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::Abacus::CreateCourseInvoiceJob do
  let(:mitglied) { people(:mitglied) }
  let(:kind) { event_kinds(:ski_course) }
  let(:course) { Fabricate(:sac_course, kind: kind) }
  let(:participation) { Fabricate(:event_participation, event: course, person: mitglied, price: 20, price_category: 1) }
  let(:now) { Time.zone.local(2024, 8, 24, 1) }
  let(:external_invoice) {
    Fabricate(:external_invoice,
      person: mitglied,
      link: participation,
      state: :draft,
      issued_at: now,
      sent_at: now,
      year: now.year,
      total: 0,
      type: "ExternalInvoice::CourseParticipation")
  }
  let(:client) { instance_double(Invoices::Abacus::Client) }

  before do
    course.dates.destroy_all
    Event::Date.create!(event: course, start_at: "01.01.2024", finish_at: "31.01.2024")
    Event::Date.create!(event: course, start_at: "01.03.2024", finish_at: "31.03.2024")
    participation.reload
    travel_to(now)
    allow(job).to receive(:client).and_return(client)
  end

  subject(:job) { described_class.new(external_invoice) }

  it "transmits subject, updates invoice total and transmit_sales_order" do
    allow_any_instance_of(Invoices::Abacus::SubjectInterface).to receive(:transmit).and_return(true)
    allow_any_instance_of(Invoices::Abacus::SalesOrderInterface).to receive(:create)
    expect do
      job.perform
    end.to change { external_invoice.reload.total }
    expect(external_invoice.total).to eq(20)
  end

  it "transmits subject and updates invoice total to custom amount parameter" do
    allow_any_instance_of(Invoices::Abacus::SubjectInterface).to receive(:transmit).and_return(true)
    allow_any_instance_of(Invoices::Abacus::SalesOrderInterface).to receive(:create)
    participation.update_column(:state, "absent")
    external_invoice.update_column(:type, ExternalInvoice::CourseAnnulation.sti_name)
    external_invoice.reload
    job.instance_variable_set(:@custom_price, 500)

    expect do
      job.perform
    end.to change { external_invoice.reload.total }
    expect(external_invoice.total).to eq(500)
  end

  context "invoice errors" do
    context "without course prices" do
      let(:log_entry) { HitobitoLogEntry.last }

      it "creates log, updates invoice state to error" do
        participation.update!(price_category: nil, price: nil)

        expect do
          job.perform
        end.to change { HitobitoLogEntry.count }.by(1)
          .and change { external_invoice.reload.state }.to("error")
        expect(log_entry.level).to eq "error"
        expect(log_entry.category).to eq "rechnungen"
        expect(log_entry.message).to eq "Diese/r Teilnehmer/in erhält keine Rechnung."
        expect(log_entry.subject).to eq external_invoice
      end
    end

    context "with subject errors" do
      it "logs error message and terminates" do
        expect_any_instance_of(Invoices::Abacus::SubjectInterface).to receive(:transmit).and_wrap_original do |original, subject|
          subject.errors[:abacus_subject_key] = :taken
          false
        end
        expect(job).not_to receive(:transmit_sales_order)

        expect do
          job.perform
        end.to change { HitobitoLogEntry.count }.by(1)
          .and change { external_invoice.reload.state }.to("error")

        log_entry = HitobitoLogEntry.last
        expect(log_entry.level).to eq "error"
        expect(log_entry.category).to eq "rechnungen"
        expect(log_entry.message).to eq "Probleme beim Übermitteln der Personendaten"
        expect(log_entry.payload).to eq "Abacus subject key ist bereits vergeben"
        expect(log_entry.subject).to eq external_invoice
      end
    end
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
  end
end
