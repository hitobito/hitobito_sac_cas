# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipInvoicesController < ApplicationController
  helper_method :invoice_possible?, :date_range, :currently_paying_zusatzsektionen

  def create
    authorize!(:create, external_invoice)

    invoice_form.attributes = invoice_form_params

    if invoice_form.valid? && create_invoice
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
    ExternalInvoice::SacMembership.create(
      state: :draft,
      year: invoice_form.reference_date.year,
      issued_at: invoice_form.invoice_date,
      sent_at: invoice_form.send_date,
      person: person,
      link: Group.find(invoice_form.section_id)
    )
  end

  def invoice_possible?
    person.sac_membership_invoice?
  end

  def date_range(attr = nil)
    max_date = (attr == :send_date && !already_member_next_year?) ? today.end_of_year : today.next_year.end_of_year

    {minDate: today.beginning_of_year, maxDate: max_date}
  end

  def already_member_next_year?
    next_year = today.next_year.year
    person.sac_membership.stammsektion_role.delete_on&.year&.>= next_year
  end

  def currently_paying_zusatzsektionen
    member = Invoices::SacMemberships::Member.new(person, context)
    person.sac_membership.zusatzsektion_roles
      .select { |membership| member.paying_person?(membership.beitragskategorie) }
      .map(&:layer_group)
  end

  def external_invoice = @external_invoice ||= ExternalInvoice.new(person: person)

  def invoice_form = @invoice_form ||= People::Membership::InvoiceForm.new({}, person)

  def person = @person ||= context.people_with_membership_years.find(params[:person_id])

  def context = @context ||= Invoices::SacMemberships::Context.new(date)

  def group = @group ||= Group.find(params[:group_id])

  def date = @date ||= params[:date].present? ? Date.parse(params[:date]) : today

  def today = @today ||= Time.zone.today
end
