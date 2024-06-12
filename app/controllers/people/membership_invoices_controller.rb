# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipInvoicesController < ApplicationController

  def create
    authorize!(:update, person)

    generate_invoice
    redirect_to group_person_path(params[:group_id], person.id)
  end

  private

  def generate_invoice
    if invoicer.generate
      set_flash(:success, abacus_key: invoicer.invoice.abacus_sales_order_key)
    else
      set_flash(:alert, message: invoicer.error_messages.join(', '))
    end
  rescue RestClient::Exception => e
    set_flash(:alert, message: "#{e.message} (#{e.response.body}")
  rescue => e
    set_flash(:alert, message: e.message)
  end

  def set_flash(type, **args)
    flash[type] = t("people.membership_invoices.#{type}_notice", **args) # rubocop:disable Rails/ActionControllerFlashBeforeRender
  end

  def invoicer
    @invoicer ||= begin
      current_role = Invoices::Abacus::MembershipInvoice.current_role(member)
      Invoices::Abacus::MembershipInvoice.new(member, current_role)
    end
  end

  def member
    @member ||= Invoices::SacMemberships::Member.new(person, context)
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(date)
  end

  def person
    @person ||= Person.with_membership_years('people.*', date).find(params[:person_id])
  end

  def date
    @date ||= params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
  end

end
