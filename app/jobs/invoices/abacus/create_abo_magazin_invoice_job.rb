# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoices::Abacus::CreateAboMagazinInvoiceJob < Invoices::Abacus::CreateInvoiceJob
  self.parameters = [:external_invoice_id, :abonnent_role_id]

  attr_reader :abonnent_role_id

  def initialize(external_invoice, abonnent_role_id)
    super(external_invoice)
    @abonnent_role_id = abonnent_role_id
  end

  private

  def invoice_data
    @invoice_data ||= Invoices::Abacus::AboMagazinInvoice.new(abonnent_role)
  end

  def abonnent_role = @abonnent_role ||= Role.find(abonnent_role_id)
end
