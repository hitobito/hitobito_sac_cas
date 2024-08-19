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

    if invoice_form.valid? && generate_invoice
      redirect_to external_invoices_group_person_path(group, person), notice: t("people.membership_invoices.success_notice")
    else
      redirect_to new_group_person_membership_invoice_path(group, person), alert: I18n.t("people.membership_invoices.alert_notice", message: invoice_form.errors.full_messages.join(", "))
    end
  end

  def new
    authorize!(:update, external_invoice)

    @invoice_form = invoice_form
    @group = group
    @member = member
  end

  private

  def external_invoice = @external_invoice ||= ExternalInvoice.new(person: person)

  def invoice_form
    @invoice_form ||= People::Membership::InvoiceForm.new({}, person)
  end

  def invoice_form_params
    params.require(:people_membership_invoice_form).permit(:reference_date, :invoice_date, :send_date, :section_id, :new_entry, :discount)
  end

  def generate_invoice
    ExternalInvoice::SacMembership.create(
      state: :draft,
      year: @invoice_form.reference_date.year,
      issued_at: @invoice_form.invoice_date,
      sent_at: @invoice_form.send_date,
      person: person,
      link: Group.find(@invoice_form.section_id)
    )
  end

  def invoice_possible?(member, date)
    memberships = member.active_memberships
    memberships.present? && Invoices::Abacus::MembershipInvoice.new(member, memberships).invoice?
  end

  def date_range(attr)
    if attr == :send_date
      Time.zone.today.beginning_of_year..(already_member_next_year?(@person) ? Time.zone.today.next_year.end_of_year : Time.zone.today.end_of_year)
    else
      Time.zone.today.beginning_of_year..Time.zone.today.next_year.end_of_year
    end
  end

  def already_member_next_year?(person)
    next_year = Time.zone.today.year + 1
    delete_on_date = person.sac_membership.stammsektion_role.delete_on
    delete_on_date >= Date.new(next_year, 1, 1) && delete_on_date <= Date.new(next_year, 12, 31)
  end

  def currently_paying_zusatzsektionen(member)
    memberships = member.additional_membership_roles + member.new_additional_section_membership_roles
    paying_memberships = memberships.select { |membership| member.paying_person?(membership.beitragskategorie) }
    paying_memberships.map(&:layer_group)
  end

  def member
    @member ||= Invoices::SacMemberships::Member.new(person, context)
  end

  def person
    @person ||= context.people_with_membership_years.find(params[:person_id])
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(date)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def date
    @date ||= params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
  end
end
