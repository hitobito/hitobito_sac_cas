# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CancelInvoiceJob < BaseJob
  self.parameters = [:external_invoice_id]

  def initialize(external_invoice)
    super()
    @external_invoice_id = external_invoice.id
  end

  def perform
    return if !external_invoice || external_invoice.state == "cancelled" # may have been deleted already

    sales_order = Invoices::Abacus::SalesOrder.new(external_invoice)
    Invoices::Abacus::SalesOrderInterface.new.cancel(sales_order)
  end

  def error(_job, exception, payload = parameters)
    HitobitoLogEntry.create!(
      level: "error",
      category: "rechnungen",
      message: exception.message,
      subject: external_invoice,
      payload: payload
    )
    super
  end

  def failure(job)
    external_invoice.update!(state: "error")
  end

  private

  def external_invoice
    @external_invoice ||= ExternalInvoice.find_by(id: @external_invoice_id)
  end
end
