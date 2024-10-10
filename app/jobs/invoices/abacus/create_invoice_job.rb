# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoices::Abacus::CreateInvoiceJob < BaseJob
  self.parameters = [:external_invoice_id]

  attr_reader :external_invoice_id

  def initialize(external_invoice)
    @external_invoice_id = external_invoice.id
  end

  def perform
    if invoice_data.invoice? && person.data_quality != "error"
      transmit_subject
      external_invoice.update!(total: invoice_data.total)
      transmit_sales_order
    else
      assign_error
    end
  end

  def error(job, exception)
    super
    create_error_log_entry(exception.to_s)
  end

  def failure(job)
    external_invoice.update!(state: :error)
  end

  private

  def assign_error
    external_invoice.update!(state: :error)
    create_error_log_entry(I18n.t(invoice_error_key))
  end

  def transmit_subject
    subject = Invoices::Abacus::Subject.new(person)
    Invoices::Abacus::SubjectInterface.new(client).transmit(subject)
  end

  def transmit_sales_order
    sales_order = Invoices::Abacus::SalesOrder.new(
      external_invoice,
      invoice_data.positions,
      invoice_data.additional_user_fields
    )
    Invoices::Abacus::SalesOrderInterface.new(client).create(sales_order)
  end

  def create_error_log_entry(message)
    HitobitoLogEntry.create!(
      message: message,
      level: :error,
      category: ExternalInvoice::ERROR_CATEGORY,
      subject: external_invoice
    )
  end

  def external_invoice
    @external_invoice ||= ExternalInvoice.find(@external_invoice_id)
  end

  def client = @client ||= Invoices::Abacus::Client.new

  def person = @person ||= Person.find(external_invoice.person_id)

  # Override in subclass
  def invoice_data
    raise NotImplementedError, "invoice_data has to be implemented in subclass"
  end

  def invoice_error_key
    raise NotImplementedError, "invoice_error_key has to be implemented in subclass"
  end
end
