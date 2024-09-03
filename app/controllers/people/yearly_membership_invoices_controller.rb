# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::YearlyMembershipInvoicesController < ApplicationController
  def new
    authorize!(:create_yearly_membership_invoice, group)

    @invoice_form = invoice_form
    @group = group
    @yearly_membership_invoice_job_running = yearly_membership_invoice_job_running?
  end

  def create
    authorize!(:create_yearly_membership_invoice, group)

    return success_redirect if yearly_membership_invoice_job_running?

    assign_attributes

    if invoice_form.valid?
      enqueue_job_and_redirect
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def assign_attributes
    invoice_form.attributes = invoice_form_params
  end

  def enqueue_job_and_redirect
    Invoices::Abacus::CreateYearlyInvoicesJob.new(
      invoice_year: invoice_form.invoice_year,
      invoice_date: invoice_form.invoice_date,
      send_date: invoice_form.send_date,
      role_finish_date: invoice_form.role_finish_date
    ).enqueue!

    success_redirect
  end

  def success_redirect
    redirect_to group_path(group), notice: t("people.yearly_membership_invoices.job_scheduling_info")
  end

  def invoice_form_params
    params.require(:people_yearly_membership_invoice_form).permit(:invoice_year, :invoice_date, :send_date, :role_finish_date)
  end

  def yearly_membership_invoice_job_running?
    Invoices::Abacus::CreateYearlyInvoicesJob.other_job_running?
  end

  def invoice_form = @invoice_form ||= People::YearlyMembership::InvoiceForm.new

  def group = @group ||= Group.find(params[:group_id])
end
