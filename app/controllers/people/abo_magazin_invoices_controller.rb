# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::AboMagazinInvoicesController < CrudController
  skip_authorize_resource
  before_action :authorize_action

  self.permitted_attrs = [:sent_at, :link_id]

  def new
    @group = group
    @abo_magazin_roles = abo_magazin_roles
    super
  end

  def create
    if person.data_quality != "error"
      entry.link_type = Group
      entry.issued_at = role_of_selected_magazin.then { (_1.type == Group::AboMagazin::Neuanmeldung.sti_name) ? _1.start_on : _1.end_on&.next_day }
      entry.year = entry.issued_at&.year
      super.then do
        Invoices::Abacus::CreateAboMagazinInvoiceJob.new(entry, role_of_selected_magazin.id).enqueue!
      end
    else
      mark_with_error_and_redirect
    end
  end

  def self.model_class
    ExternalInvoice::AboMagazin
  end

  private

  def authorize_action
    authorize!(:create_abo_magazin_invoice, person)
  end

  def build_entry
    model_class.new(person: person)
  end

  def mark_with_error_and_redirect
    entry.update(state: :error)
    HitobitoLogEntry.create!(
      level: :error,
      message: t("invoices.errors.data_quality_error"),
      category: model_class::ERROR_CATEGORY,
      subject: entry
    )
    redirect_to external_invoices_group_person_path(group, person), alert: t("invoices.errors.data_quality_error")
  end

  def person = @person ||= Person.find(params[:person_id])

  def group = @group ||= Group.find(params[:group_id])

  def role_of_selected_magazin = @role_of_selected_magazin ||= abo_magazin_roles.where(group_id: permitted_params[:link_id]).first

  def abo_magazin_roles
    @abo_magazin_roles ||= person.sac_membership.recent_abonnent_magazin_roles
  end
end
