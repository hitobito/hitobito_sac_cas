# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoices::Abacus::CreateMembershipInvoiceJob < Invoices::Abacus::CreateInvoiceJob
  self.parameters = [:external_invoice_id, :reference_date, :discount, :new_entry]

  attr_reader :reference_date, :discount, :new_entry

  def initialize(external_invoice, reference_date, discount: nil, new_entry: false)
    super(external_invoice)
    @reference_date = reference_date
    @discount = discount
    @new_entry = new_entry
  end

  private

  def invoice_data
    @membership ||= Invoices::Abacus::MembershipInvoiceGenerator
      .new(external_invoice.person_id, external_invoice.link, reference_date, custom_discount: discount)
      .build(new_entry: new_entry)
  end

  def invoice_error_key
    if person.data_quality == "error"
      ExternalInvoice::SacMembership::DATA_QUALITY_ERROR_KEY
    elsif invoice_data.memberships.none?
      ExternalInvoice::SacMembership::NO_MEMBERSHIPS_KEY
    else
      ExternalInvoice::SacMembership::NOT_POSSIBLE_KEY
    end
  end
end