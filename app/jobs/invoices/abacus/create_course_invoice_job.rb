# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CreateCourseInvoiceJob < Invoices::Abacus::CreateInvoiceJob
  def initialize(external_invoice)
    super
  end

  def invoice_data
    Invoices::Abacus::CourseInvoice.new(external_invoice.link)
  end

  def invoice_error_key
    ExternalInvoice::Course::NOT_POSSIBLE_KEY
  end
end
