# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CreateCourseInvoiceJob < Invoices::Abacus::CreateInvoiceJob
  def initialize(external_invoice, invoice_total = nil)
    super(external_invoice)
    @invoice_total = invoice_total
  end

  def invoice_data
    @invoice_data ||=
      external_invoice.is_a?(ExternalInvoice::CourseAnnulation) ?
      Invoices::Abacus::CourseAnnulationInvoice.new(external_invoice.link, @invoice_total) :
      Invoices::Abacus::CourseParticipationInvoice.new(external_invoice.link)
  end

  def default_invoice_error_message
    I18n.t("invoices.course_participation.no_invoice_possible")
  end
end
