# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoices::Abacus::CreateMembershipInvoiceJob < Invoices::Abacus::CreateInvoiceJob
  self.parameters = [:external_invoice_id, :reference_date, :discount, :new_entry,
    :dont_send, :dispatch_type, :manual_positions]

  attr_reader :reference_date, :discount, :new_entry, :dont_send, :dispatch_type, :manual_positions

  def initialize(external_invoice, reference_date, discount: nil, new_entry: false,
    dont_send: false, dispatch_type: nil, manual_positions: nil)
    super(external_invoice)
    @reference_date = reference_date
    @discount = discount
    @new_entry = new_entry
    @dont_send = dont_send
    @dispatch_type = dispatch_type
    @manual_positions = manual_positions
  end

  private

  def invoice_data
    @invoice_data ||= Invoices::Abacus::MembershipInvoiceGenerator
      .new(external_invoice.person_id,
        external_invoice.link,
        reference_date,
        custom_discount: discount)
      .build(new_entry:, dispatch_type:, manual_positions:)
  end

  def transmit_sales_order
    external_invoice.invoice_kind = :sac_membership_not_sent if dont_send
    super
  end

  def default_invoice_error_message
    if invoice_data.memberships.none?
      I18n.t("people.membership_invoices.no_memberships")
    else
      I18n.t("people.membership_invoices.no_invoice_possible")
    end
  end
end
