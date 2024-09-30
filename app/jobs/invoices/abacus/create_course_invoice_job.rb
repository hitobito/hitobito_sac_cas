# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CreateCourseInvoiceJob < BaseJob
  self.parameters = [:external_invoice_id]

  def initialize(external_invoice)
    super()
    @external_invoice_id = external_invoice.id
  end

  def perform
    "TODO: SAC#1008"
  end

  private

  def external_invoice
    @external_invoice ||= ExternalInvoice.find_by(id: @external_invoice_id)
  end
end
