# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipInvoicesController < ApplicationController
  def create
    authorize!(:update, person)

    errors = validate_params(params[:reference_date], params[:invoice_date], params[:send_date])

    if errors.any?
      set_flash(:alert, message: "#{errors.join(', ')}")
      redirect_to new_group_person_membership_invoice_path(group, person)
    else
      generate_invoice
      redirect_to external_invoices_group_person_path(group, person)
    end
  end

  def new
    authorize!(:update, member)

    @group = group
  end

  private

  def validate_params(reference_date, invoice_date, send_date)
    [reference_date, invoice_date, send_date]
      .zip(['Stichtag', 'Rechnungsdatum', 'Versanddatum'])
      .map { |date, field| "#{field} muss vorhanden sein" if date.blank? }
      .compact
  end

  def generate_invoice
    handle_exceptions do
     ExternalInvoice::SacMembership.create!(
      state: :draft,
      year: Date.parse(params[:reference_date]).year,
      issued_at: params[:invoice_date],
      sent_at: params[:send_date],
      person: person,
      link: Group.find(params[:section_id]),
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
