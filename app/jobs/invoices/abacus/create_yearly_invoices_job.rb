# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CreateYearlyInvoicesJob < BaseJob
  self.parameters = [:invoice_year, :invoice_date, :send_date, :role_finish_date]

  def initialize(invoice_year:, invoice_date:, send_date:, role_finish_date:)
    super()
    @invoice_year = invoice_year
    @invoice_date = invoice_date
    @send_date = send_date
    @role_finish_date = role_finish_date
  end

  def perform
  end
end
