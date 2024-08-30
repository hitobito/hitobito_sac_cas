# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::CreateYearlyInvoicesJob < BaseJob
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

  def enqueue!(options = {})
    assert_no_other_job_running!
    super
  end

  def error(job, exception)
    super
    create_error_log_entry("Mitgliedschaftsrechnungen konnten nicht an Abacus übermittelt werden. " \
              "Es erfolgt ein weiterer Versuch.", exception.message)
  end

  def failure(job)
    create_error_log_entry("MV-Jahresinkassolauf abgebrochen", nil)
  end

  def perform
    log_progress(0)
    extend_roles_for_invoicing
    process_invoices
    log_progress(100)
  end

  def active_members
    Person
      .where.not(abacus_subject_key: nil)
      .where.not(data_quality: :error)
      .joins(:roles)
      .merge(Role.active(Date.new(@invoice_year)))
      .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name})
      .left_outer_joins(:external_invoices)
      .where("external_invoices.id IS NULL OR external_invoices.type != ? OR external_invoices.year != ?", ExternalInvoice::SacMembership.sti_name, @invoice_year)
      .distinct
  end

  private

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

  def assert_no_other_job_running!
    raise "There is already a job running" if other_job_running?
  end

  def other_job_running?
    Delayed::Job.where("handler LIKE ?", "%Invoices::Abacus::CreateYearlyInvoicesJob%")
      .where(failed_at: nil).exists?
  end

  def extend_roles_for_invoicing
    return if @role_finish_date.nil?

    Invoices::SacMemberships::ExtendRolesForInvoicing.new(@role_finish_date).extend_roles
  end

  def process_invoices
    current_logged_percent = 0
    members_count = active_members.count
    processed_members = 0
    raise_exception = nil
    active_members.in_batches(of: BATCH_SIZE) do |people|
      slices = people.pluck(:id).each_slice(SLICE_SIZE).to_a
      Parallel.map(slices, in_threads: PARALLEL_THREADS) do |ids|
        # TODO: Call check_terminated https://github.com/hitobito/hitobito/issues/2772
        ActiveRecord::Base.connection_pool.with_connection do
          create_invoices(load_people(ids))
        end
      # rubocop:disable Lint/RescueException we want to catch and re-raise all exceptions
      rescue Exception => e
        Rails.logger.error "Error while creating invoices: #{e.message}"
        raise_exception = e
        raise Parallel::Break
      end
      # rubocop:enable Lint/RescueException
      processed_members += people.count # Can't use BATCH_SIZE since we would end up with more than 100%
      progress_percent = processed_members * 100 / members_count
      if progress_percent >= (current_logged_percent + 10)
        current_logged_percent = progress_percent / 10 * 10
        log_progress(current_logged_percent)
      end
      if raise_exception
        raise raise_exception
      end
    end
  end

  def load_people(ids)
    context.people_with_membership_years.where(id: ids).order(:id).includes(:roles)
  end

  def create_invoices(people)
    membership_invoices = membership_invoices(people)
    sales_orders = create_sales_orders(membership_invoices)

    parts = begin
      sales_order_interface.create_batch(sales_orders)
    rescue RestClient::ExceptionWithResponse => e
      # Clear external invoices from the sales_orders object
      Rails.logger.error "Error while creating sales orders: #{e.response.body}"
      sales_orders.each do |so|
        so.entity.destroy
      end
      raise e
    end
    log_error_parts(parts)
  end

  def membership_invoices(people)
    people.filter_map do |person|
      member = Invoices::SacMemberships::Member.new(person, context)
      if member.stammsektion_role
        invoice = Invoices::Abacus::MembershipInvoice.new(member, member.active_memberships)
        invoice if invoice.invoice?
      end
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

  def context
    @context ||= Invoices::SacMemberships::Context.new(Date.new(@invoice_year))
  end

  def sales_order_interface
    @sales_order_interface ||= Invoices::Abacus::SalesOrderInterface.new
  end
end
