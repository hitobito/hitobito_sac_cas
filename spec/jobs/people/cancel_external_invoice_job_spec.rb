# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::CancelExternalInvoiceJob do
  let(:invoice) { Fabricate(:external_invoice, person_id: people(:mitglied)) }
  let(:job) { described_class.new(invoice) }

  context "when the job works" do
    let(:sales_order_interface) { double }

    before do
      sales_order = double
      allow(Invoices::Abacus::SalesOrder).to receive(:new).with(any_args)
        .and_return(sales_order)
      allow(Invoices::Abacus::SalesOrderInterface).to receive(:new).and_return(sales_order_interface)
      allow(sales_order_interface).to receive(:cancel).with(any_args)
        .and_return(true)
    end

    it "does not update the invoice status" do
      job.perform
      expect(invoice.reload.state).to eq("open")
    end

    it "cancels the invoice in the abacus system" do
      expect(sales_order_interface).to receive(:cancel)
      job.perform
    end
  end

  context "when the job fails" do
    it "logs an error" do
      job = described_class.new(invoice)

      expect do
        job.error(job, StandardError.new("error message").tap { |e| e.set_backtrace(caller) })
      end.to change { HitobitoLogEntry.where(level: "error").count }.by(1)
    end

    it "updates the invoice status to error" do
      job = described_class.new(invoice)
      job.failure(job)

      expect(invoice.reload.state).to eq("error")
    end
  end
end
