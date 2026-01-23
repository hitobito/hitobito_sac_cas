# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipInvoicesController < ApplicationController
  helper_method :member, :context

  def new
    authorize!(:update, external_invoice)

    set_initial_form_values
    @group = group
  end

  def create
    authorize!(:create, external_invoice)
    assign_attributes

    if invoice_form.valid? && external_invoice.valid? && external_invoice.save
      if person.data_quality != "error"
        enqueue_job_and_redirect
      else
        mark_with_error_and_redirect("invoices.errors.data_quality_error")
      end
    else
      @group = group
      render :new, status: :unprocessable_content
    end
  end

  private

  def assign_attributes
    invoice_form.attributes = invoice_form_params
    external_invoice.attributes = {
      state: :draft,
      link: link_group,
      year: invoice_form.reference_date&.year,
      issued_at: invoice_form.invoice_date,
      sent_at: invoice_form.send_date
    }
  end

  def enqueue_job_and_redirect
    Invoices::Abacus::CreateMembershipInvoiceJob.new(
      external_invoice,
      invoice_form.reference_date,
      discount: invoice_form.discount,
      new_entry: invoice_form.new_entry,
      dont_send: invoice_form.dont_send,
      manual_positions: invoice_form.manual_positions
    ).enqueue!

    redirect_to external_invoices_group_person_path(group, person),
      notice: t("people.membership_invoices.success_notice")
  end

  def mark_with_error_and_redirect(key)
    external_invoice.update(state: :error)
    HitobitoLogEntry.create!(
      level: :error,
      message: t(key),
      category: ExternalInvoice::SacMembership::ERROR_CATEGORY,
      subject: external_invoice
    )
    redirect_to external_invoices_group_person_path(group, person), alert: t(key)
  end

  def invoice_form_params
    params
      .require(:people_membership_invoice_form)
      .permit(:reference_date, :invoice_date, :send_date,
        :section_id, :new_entry, :discount, :dont_send,
        :sac_fee, :sac_entry_fee, :hut_solidarity_fee,
        :sac_magazine, :sac_magazine_postage_abroad, :section_entry_fee,
        section_fees_attributes: [:section_id, :fee],
        section_bulletin_postage_abroad_attributes: [:section_id, :fee])
  end

  def set_initial_form_values
    invoice_form.invoice_date = today
    invoice_form.send_date = today
    invoice_form.section_fees = invoice_form.initial_section_fees
    invoice_form.section_bulletin_postage_abroad = invoice_form.initial_bulletin_postage_abroad
  end

  def external_invoice = @external_invoice ||= ExternalInvoice::SacMembership.new(person: person)

  def invoice_form = @invoice_form ||= People::Membership::InvoiceForm.new(person)

  def person = @person ||= Person.find(params[:person_id])

  def group = @group ||= Group.find(params[:group_id])

  def link_group
    if invoice_form.manual_positions?
      invoice_form.member.stammsektion
    else
      Group.find(invoice_form.section_id)
    end
  end

  def date = @date ||= params[:date].present? ? Date.parse(params[:date]) : today

  def today = @today ||= Time.zone.today
end
