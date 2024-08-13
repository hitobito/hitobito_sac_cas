# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipInvoicesController < ApplicationController
  def create
    authorize!(:update, person)

    invoice_form.attributes = invoice_form_params

    if invoice_form.valid?
      generate_invoice
      redirect_to external_invoices_group_person_path(group, person)
    else
      set_flash(:alert, message: invoice_form.errors.full_messages.join(", "))
      redirect_to new_group_person_membership_invoice_path(group, person)
    end
  end

  def new
    authorize!(:update, person)

    @invoice_form = invoice_form
    @group = group
    @date = date
    @person = person
    @context = context
    @member = member
  end

  private

  def invoice_form
    @invoice_form ||= People::Membership::Invoice.new({}, person)
  end

  def invoice_form_params
    params.require(:people_membership_invoice).permit(:reference_date, :invoice_date, :send_date, :section_id, :new_entry, :discount)
  end

  def generate_invoice
    handle_exceptions do
      ExternalInvoice::SacMembership.create!(
        state: :draft,
        year: Date.parse(@invoice_form.reference_date).year,
        issued_at: @invoice_form.invoice_date,
        sent_at: @invoice_form.send_date,
        person: person,
        link: Group.find(@invoice_form.section_id)
      )
      set_flash(:success)
    end
  end

  def set_flash(type, **args)
    kind = (type == :success) ? :notice : :alert
    flash[kind] = t("people.membership_invoices.#{type}_notice", **args) # rubocop:disable Rails/ActionControllerFlashBeforeRender
  end

  def handle_exceptions
    yield
  rescue => e
    set_flash(:alert, message: e.message)
    options = {}
    if e.respond_to?(:response)
      options[:extra] = {response: e.response.body.force_encoding("UTF-8")}
    end
    Raven.capture_exception(e, options)
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

  def context
    @context ||= Invoices::SacMemberships::Context.new(date)
  end

  def date
    @date ||= params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
  end
end
