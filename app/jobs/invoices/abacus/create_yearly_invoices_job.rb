# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CreateYearlyInvoicesJob < BaseJob
  include GracefulTermination

  BATCH_SIZE = 500 # number of people loaded per query
  SLICE_SIZE = 25  # number of people/invoices transmitted per abacus batch request
  PARALLEL_THREADS = 4 # number of threads sending abacus requests

  self.parameters = [:invoice_year, :invoice_date, :send_date, :role_finish_date]
  self.max_run_time = 24.hours

  def initialize(invoice_year:, invoice_date:, send_date:, role_finish_date:)
    super()
    raise ArgumentError, "invoice_year must be a positive integer" unless invoice_year.positive?
    raise ArgumentError, "invoice_date must be a Date instance" unless invoice_date.is_a?(Date)
    @invoice_year = invoice_year
    @invoice_date = invoice_date
    @send_date = send_date
    @role_finish_date = role_finish_date
  end

  def perform
    handle_termination_signals do
      log_progress(0)
      clear_spurious_draft_invoices!
      extend_roles_for_invoicing
      process_invoices
      log_progress(100) if @current_logged_percent < 100
    end
  end

  def enqueue
    assert_no_other_job_running!
  end

  def error(job, exception)
    super
    create_error_log_entry("Mitgliedschaftsrechnungen konnten nicht an Abacus übermittelt werden. " \
              "Es erfolgt ein weiterer Versuch.", exception.message)
  end

  def failure(job)
    create_error_log_entry("MV-Jahresinkassolauf abgebrochen", nil)
  end

  def active_members
    Person
      .where.not(abacus_subject_key: nil)
      .where.not(data_quality: :error)
      .joins(:roles)
      .merge(Role.active(reference_date))
      .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name})
      .where.not(id: ExternalInvoice::SacMembership.where(year: @invoice_year).select(:person_id))
      .distinct
  end

  def self.job_running?
    Delayed::Job.where("handler LIKE ?", "%#{name}%")
      .where(failed_at: nil).exists?
  end

  private

  def process_invoices
    start_progress
    active_members.in_batches(of: BATCH_SIZE) do |people|
      check_terminated!
      people_ids = people.pluck(:id)
      create_invoices_in_parallel(people_ids)
      update_progress(people_ids.size)
    end
  end

  def create_invoices_in_parallel(people_ids)
    raise_exception = nil
    slices = people_ids.each_slice(SLICE_SIZE).to_a
    Parallel.map(slices, in_threads: PARALLEL_THREADS) do |ids|
      check_terminated!
      ActiveRecord::Base.connection_pool.with_connection do
        create_invoices(load_people(ids))
      end
    rescue Exception => e # rubocop:disable Lint/RescueException we want to catch and re-raise all exceptions
      raise_exception = e
      raise Parallel::Break
    end
    raise raise_exception if raise_exception
  end

  def create_invoices(people)
    membership_invoices = membership_invoices(people)
    sales_orders = create_sales_orders(membership_invoices)
    parts = submit_sales_orders(sales_orders)
    log_error_parts(parts)
  end

  def submit_sales_orders(sales_orders)
    sales_order_interface.create_batch(sales_orders)
  rescue RestClient::Exception => e
    clear_external_invoices(sales_orders)
    raise e
  end

  def clear_external_invoices(sales_orders)
    sales_orders.each do |so|
      so.entity.destroy
    end
  end

  def membership_invoices(people)
    people.filter_map do |person|
      member = Invoices::SacMemberships::Member.new(person, context)
      invoice = Invoices::Abacus::MembershipInvoice.new(member, member.active_memberships)
      invoice if invoice.invoice?
    end
  end

  def create_sales_orders(membership_invoices)
    membership_invoices.map do |mi|
      invoice = create_external_invoice(mi)
      Invoices::Abacus::SalesOrder.new(invoice, mi.positions, mi.additional_user_fields)
    end
  end

  def create_external_invoice(membership_invoice)
    ExternalInvoice::SacMembership.create!(
      person: membership_invoice.member.person,
      year: @invoice_year,
      state: :draft,
      total: membership_invoice.total,
      issued_at: @invoice_date,
      sent_at: @send_date,
      # also see comment in ExternalInvoice::SacMembership
      link: membership_invoice.member.stammsektion
    )
  end

  def assert_no_other_job_running!
    raise "There is already a job running" if self.class.job_running?
  end

  # clears invoice models from previously failed job runs
  def clear_spurious_draft_invoices!
    ExternalInvoice::SacMembership.where(state: :draft, year: @invoice_year).destroy_all
  end

  def extend_roles_for_invoicing
    return if @role_finish_date.nil?

    Invoices::SacMemberships::ExtendRolesForInvoicing.new(@role_finish_date).extend_roles
  end

  def start_progress
    @current_logged_percent = 0
    @members_count = active_members.count
    @processed_members = 0
  end

  def update_progress(people_count)
    @processed_members += people_count
    @progress_percent = @processed_members * 100 / @members_count
    if @progress_percent >= (@current_logged_percent + 10)
      @current_logged_percent = @progress_percent / 10 * 10
      log_progress(@current_logged_percent)
    end
  end

  def load_people(ids)
    context.people_with_membership_years.where(id: ids).order(:id).includes(:roles)
  end

  def log_progress(percent)
    HitobitoLogEntry.create!(
      category: "stapelverarbeitung",
      level: :info,
      message: "MV-Jahresinkassolauf: Fortschritt #{percent}%"
    )
  end

  def create_error_log_entry(message, payload)
    HitobitoLogEntry.create!(
      category: "stapelverarbeitung",
      level: :error,
      message: message,
      payload: payload
    )
  end

  def log_error_parts(parts)
    parts.reject(&:success?).each do |part|
      create_log_entry(part)
    end
  end

  def create_log_entry(part)
    part.context_object.entity.update!(state: :error)
    HitobitoLogEntry.create!(
      subject: part.context_object.entity,
      category: "rechnungen",
      level: :error,
      message: "Mitgliedschaftsrechnung konnte nicht in Abacus erstellt werden",
      payload: part.error_payload
    )
  end

  def reference_date
    @reference_date ||= Date.new(@invoice_year)
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(reference_date)
  end

  def sales_order_interface
    @sales_order_interface ||= Invoices::Abacus::SalesOrderInterface.new
  end
end
