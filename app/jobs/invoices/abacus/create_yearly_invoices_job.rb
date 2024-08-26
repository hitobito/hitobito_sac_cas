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
    @invoice_year = invoice_year
    @invoice_date = invoice_date
    @send_date = send_date
    @role_finish_date = role_finish_date
  end

  def perform
    # abort_if_other_job_is_running
    # log start according to ticket
    extend_roles_for_invoicing
    # process_invoices
    # log finish according to ticket
  end

  private

  def extend_roles_for_invoicing
    return if @role_finish_date.nil?

    Invoices::SacMemberships::ExtendRolesForInvoicing.new(@role_finish_date).extend_roles
  end

  def process_invoices
    active_members.in_batches(of: BATCH_SIZE) do |people|
      slices = people.pluck(:id).each_slice(SLICE_SIZE).to_a
      Parallel.map(slices, in_threads: PARALLEL_THREADS) do |ids|
        # check_terminated
        ActiveRecord::Base.connection_pool.with_connection do
          create_invoices(load_people(ids))
        end
        # TODO: rescue errors to gracefully terminate and clean up threads. see ticket
      end
      # TODO: log progress according to ticket
    end
  end

  def active_members
    # TODO: filter according to ticket
    People.all
  end

  def load_people(ids)
    context.people_with_membership_years.where(id: ids).order(:id).includes(:roles)
  end

  def create_invoices(people)
    membership_invoices = membership_invoices(people)
    sales_orders = create_sales_orders(membership_invoices)
    parts = sales_order_interface.create_batch(sales_orders)
    log_error_parts(parts)
  end

  def membership_invoices(people)
    people.filter_map do |person|
      member = Invoices::SacMemberships::Member.new(person, context)
      if member.stammsektion_role
        invoice = MembershipInvoice.new(member, member.active_memberships)
        invoice if invoice.invoice?
      end
    end
  end

  def create_sales_orders(membership_invoices)
    membership_invoices.map do |mi|
      invoice = create_external_invoice(mi)
      SalesOrder.new(invoice, mi.positions, mi.additional_user_fields)
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
    HitobitoLogEntry.create!(
      subject: part.context_object.entity,
      category: "rechnungen",
      level: :error,
      message: "TODO",
      payload: part.error_payload
    )
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(@invoice_date)
  end

  def sales_order_interface
    @sales_order_interface ||= SalesOrderInterface.new
  end
end
