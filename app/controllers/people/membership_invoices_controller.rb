# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipInvoicesController < ApplicationController
  def create
    authorize!(:create, external_invoice)

    invoice_form.attributes = invoice_form_params

    if invoice_form.valid? && create_invoice
      enqueue_membership_invoice_job
      redirect_to external_invoices_group_person_path(group, person), notice: t("people.membership_invoices.success_notice")
    else
      @group = group
      render :new, status: :unprocessable_entity
    end
  end

  def new
    authorize!(:update, external_invoice)

    @invoice_form = invoice_form
    @group = group
  end

  private

  def invoice_form_params
    params.require(:people_membership_invoice_form).permit(:reference_date, :invoice_date, :send_date, :section_id, :new_entry, :discount)
  end

  def create_invoice
    external_invoice.assign_attributes(
      state: :draft,
      year: invoice_form.reference_date.year,
      issued_at: invoice_form.invoice_date,
      sent_at: invoice_form.send_date,
      link: Group.find(invoice_form.section_id)
    )
    external_invoice.save!
  end

  def external_invoice = @external_invoice ||= ExternalInvoice::SacMembership.new(person: person)

  def enqueue_membership_invoice_job
    membership_invoice = @external_invoice.build_membership_invoice(invoice_form.discount, invoice_form.new_entry, invoice_form.reference_date)

    if membership_invoice.is_a?(Invoices::Abacus::MembershipInvoice)
      CreateMembershipInvoiceJob.new(@external_invoice.id, invoice_form.discount, invoice_form.new_entry, invoice_form.reference_date).enqueue!
    else
      handle_invoice_generation_error(membership_invoice)
    end
  end

  def handle_invoice_generation_error(membership_invoice)
    external_invoice.update!(state: :error)
    HitobitoLogEntry.create!(
      message: membership_invoice,
      level: :error,
      category: "rechnungen",
      subject: external_invoice
    )
  end

  def invoice_form = @invoice_form ||= People::Membership::InvoiceForm.new({}, person)

  def person = @person ||= context.people_with_membership_years.find(params[:person_id])

  def context = @context ||= Invoices::SacMemberships::Context.new(date)

  def group = @group ||= Group.find(params[:group_id])

  def date = @date ||= params[:date].present? ? Date.parse(params[:date]) : today

  def today = @today ||= Time.zone.today
end
