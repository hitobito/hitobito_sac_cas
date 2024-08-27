# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoices::Abacus::CreateInvoiceJob < BaseJob
  self.parameters = [:external_invoice_id, :reference_date, :discount, :new_entry]

  attr_reader :external_invoice_id, :reference_date, :discount, :new_entry

  def initialize(external_invoice_id, reference_date, discount: nil, new_entry: false)
    @external_invoice_id = external_invoice_id
    @reference_date = reference_date
    @discount = discount
    @new_entry = new_entry
  end

  def perform
    if membership_invoice.invoice? && person.data_quality != "error"
      transmit_subject
      external_invoice.update!(total: membership_invoice.total)
      transmit_sales_order
      return
    end

    external_invoice.update!(state: :error)
    create_error_log_entry(I18n.t(
      if person.data_quality == "error"
        ExternalInvoice::SacMembership::DATA_QUALITY_ERROR_KEY
      elsif membership_invoice.memberships.none?
        ExternalInvoice::SacMembership::NO_MEMBERSHIPS_KEY
      else
        ExternalInvoice::SacMembership::NOT_POSSIBLE_KEY
      end
    ))
  end

  def error(job, exception)
    super

    create_error_log_entry(exception.to_s)
  end

  def failure(job)
    external_invoice.update!(state: :error)
  end

  private

  def transmit_subject
    subject = Invoices::Abacus::Subject.new(person)
    Invoices::Abacus::SubjectInterface.new(client).transmit(subject)
  end

  def transmit_sales_order
    sales_order = Invoices::Abacus::SalesOrder.new(
      external_invoice,
      membership_invoice.positions,
      membership_invoice.additional_user_fields
    )
    Invoices::Abacus::SalesOrderInterface.new(client).create(sales_order)
  end

  def create_error_log_entry(message)
    HitobitoLogEntry.create!(
      message: message,
      level: :error,
      category: ExternalInvoice::SacMembership::ERROR_CATEGORY,
      subject: external_invoice
    )
  end

  def membership_invoice
    @membership ||= Invoices::Abacus::MembershipInvoiceGenerator
      .new(external_invoice.person_id, external_invoice.link, reference_date)
      .build(new_entry: new_entry, discount: discount)
  end

  def external_invoice = @external_invoice ||= ExternalInvoice.find(external_invoice_id)

  def client = @client ||= Invoices::Abacus::Client.new

  def person = @person ||= Person.find(external_invoice.person_id)
end
