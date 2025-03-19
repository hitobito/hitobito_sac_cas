# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Courses::InvoicesController < ApplicationController
  before_action :authorize_action

  def create
    assign_attributes

    if invoice_form.valid?
      @participation.update!(price: invoice_form_params[:price], price_category: invoice_form_params[:price_category]) if invoice_type == ExternalInvoice::CourseParticipation
      create_invoice
      redirect_to group_event_participation_path(params[:group_id], params[:event_id], params[:participation_id])
    else
      render_invoice_form(response_status: :unprocessable_entity)
    end
  end

  def new
    invoice_form.tap do |form|
      form.reference_date = form.invoice_date = form.send_date = today
    end
    render_invoice_form
  end

  def recalculate
    assign_attributes
    if invoice_form_params[:reference_date]
      process_parameter(:reference_date) { render json: {value: calculate_annulation_price} }
    elsif invoice_form_params[:price_category]
      process_parameter(:price_category) { render json: {value: calculate_participation_price} }
    else
      render json: {error: "Invalid query param", status: :bad_request}, status: :bad_request
    end
  end

  private

  def process_parameter(attribute)
    invoice_form.send(:"#{attribute}=", invoice_form_params[attribute])
    invoice_form.valid?
    return render_validation_error(attribute) if invoice_form.errors[attribute].present?
    yield
  end

  def render_validation_error(attribute)
    render json: {errors: {attribute => invoice_form.errors[attribute].first}}, status: :unprocessable_entity
  end

  def render_invoice_form(response_status: :ok)
    @group = group
    @event = event
    @participation = participation
    @invoice_type = invoice_type
    render :new, status: response_status
  end

  def create_invoice
    invoice = invoice_type.invoice!(participation, issued_at: invoice_form.invoice_date,
      sent_at: invoice_form.send_date,
      custom_price: invoice_form.price)
    flash[:notice] = if invoice
      t("event.participations.invoice_created_notice")
    else
      t("event.participations.invoice_not_created_alert")
    end
    invoice
  end

  def calculate_annulation_price
    participation.canceled_at = invoice_form.reference_date
    Invoices::Abacus::CourseAnnulationCost.new(participation).amount_cancelled
  end

  def calculate_participation_price
    event.send(invoice_form.price_category)
  end

  def assign_attributes
    invoice_form.attributes = invoice_form_params
  end

  def invoice_form_params
    params
      .require(:event_participation_invoice_form)
      .permit(:reference_date, :invoice_date, :send_date, :price_category, :price)
  end

  def authorize_action
    raise CanCan::AccessDenied if participation.roles.exists?(type: SacCas::EVENT_LEADER_ROLES.map(&:sti_name))

    authorize!(:summon, participation)
  end

  def group = @group ||= Group.find(params[:group_id])

  def event = @event ||= Event::Course.find(params[:event_id]).decorate

  def participation = @participation ||= Event::Participation.find(params[:participation_id]).decorate

  def invoice_form = @invoice_form ||= Event::Participation::InvoiceForm.new(participation, annulation: invoice_type == ExternalInvoice::CourseAnnulation)

  def invoice_type = @invoice_type ||= participation.state.in?(%w[canceled absent]) ? ExternalInvoice::CourseAnnulation : ExternalInvoice::CourseParticipation

  def today = @today ||= Time.zone.today
end
