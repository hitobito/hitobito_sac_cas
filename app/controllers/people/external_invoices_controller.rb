# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::ExternalInvoicesController < ListController
  def cancel # rubocop:todo Metrics/AbcSize
    authorize!(:cancel_external_invoice, invoice)
    invoice.state = "cancelled"
    invoice.save!
    Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
    flash[:notice] =
      t(".flash", invoice: invoice.title, abacus_sales_order_key: invoice.abacus_sales_order_key)
    redirect_to external_invoices_group_person_path(group, person)
  end

  def show
    person_id = invoice.person_id
    group_id = Person.where(id: person_id).pick(:primary_group_id)
    redirect_to external_invoices_group_person_path(group_id, person_id)
  end

  private

  def list_entries
    super.list
      .where(person: person)
      .where(search_conditions)
      .page(params[:page]).per(50)
  end

  def person
    @person ||= fetch_person
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def invoice
    @invoice ||= ExternalInvoice.find(params[:invoice_id])
  end

  def authorize_class
    authorize!(:index_external_invoices, person)
  end
end
