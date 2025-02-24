# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CreateYearlyAboAlpenInvoicesJob < RecurringJob
  SLICE_SIZE = 25  # number of people/invoices transmitted per abacus batch request

  def perform_internal
    process_invoices
  end

  def next_run
    # Sets next run to 02:18 of next day
    Time.zone.tomorrow.at_beginning_of_day.change(hour: 2, minute: 18).in_time_zone
  end

  def error(job, exception)
    create_error_log_entry("stapelverarbeitung", "Jahresrechnungen Abo Magazin Die Alpen konnten nicht an Abacus übermittelt werden. " \
              "Es erfolgt ein weiterer Versuch.", exception.message)
  end

  def failure(job)
    create_error_log_entry("stapelverarbeitung", "Rollierender Inkassolauf Abo Magazin Die Alpen abgebrochen.", nil)
  end

  private

  def active_abonnenten
    Role.joins(:person)
      .where.not(people: {abacus_subject_key: nil})
      .where(type: Group::AboMagazin::Abonnent.sti_name, terminated: false)
      .where(end_on: Time.zone.today..62.days.from_now)
      .where.not(
        "EXISTS (
        SELECT 1 FROM external_invoices
        WHERE external_invoices.person_id = people.id
        AND external_invoices.year = EXTRACT(YEAR FROM roles.end_on + INTERVAL '1 day')
        AND external_invoices.type = ?)", ExternalInvoice::AboMagazin.sti_name
      )
      .distinct
  end

  def process_invoices
    active_abonnenten.in_batches(of: SLICE_SIZE) do |batch|
      sales_orders = batch.map { |abonnent_role| create_invoice(abonnent_role) }
      parts = submit_sales_orders(sales_orders)
      log_error_parts(parts)
    end
  end

  def create_invoice(abonnent_role)
    abo_magazin_invoice = build_abo_magazin_invoice(abonnent_role)
    invoice = create_external_invoice(abo_magazin_invoice)
    create_sales_order(invoice, abo_magazin_invoice)
  end

  def submit_sales_orders(sales_orders)
    sales_orders.each_slice(SLICE_SIZE).map do |batch|
      sales_order_interface.create_batch(batch)
    rescue RestClient::Exception => e
      clear_external_invoices(batch)
      raise e
    end.flatten
  end

  def clear_external_invoices(sales_orders)
    sales_orders.each do |so|
      so.entity.destroy
    end
  end

  def create_external_invoice(abo_magazin_invoice)
    ExternalInvoice::AboMagazin.create!(
      person: abo_magazin_invoice.person,
      year: (abo_magazin_invoice.abonnent_role.end_on + 1.day).year,
      state: :draft,
      total: abo_magazin_invoice.total,
      issued_at: abo_magazin_invoice.abonnent_role.end_on + 1.day,
      sent_at: 2.days.from_now,
      link: abo_magazin_invoice.abonnent_role.group
    )
  end

  def create_error_log_entry(category, message, payload, subject = nil)
    HitobitoLogEntry.create!(
      category: category,
      level: :error,
      message: message,
      payload: payload
    )
  end

  def log_error_parts(parts)
    parts.reject(&:success?).each do |part|
      part.context_object.entity.update!(state: :error)
      create_log_entry(part)
    end
  end

  def create_log_entry(part)
    part.context_object.entity.update!(state: :error)
    create_error_log_entry("rechnungen", "Jahresrechnung Abo Magazin Die Alpen konnte nicht in Abacus erstellt werden", part.error_payload, part.context_object.entity)
  end

  def build_abo_magazin_invoice(abonnent_role) = Invoices::Abacus::AboMagazinInvoice.new(abonnent_role)

  def create_sales_order(invoice, abo_magazin_invoice) = Invoices::Abacus::SalesOrder.new(invoice, abo_magazin_invoice.positions)

  def sales_order_interface = @sales_order_interface ||= Invoices::Abacus::SalesOrderInterface.new
end
