#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Courses::LeaderSettlementPdfsController < ApplicationController
  include AsyncDownload

  def create
    authorize!(:create, Event::Courses::LeaderSettlementInvoice.new) # TODO
    @group = group
    @event = event
    assign_attributes

    if invoice_form.valid?
      render_pdf_in_background
    else
      render turbo_stream: turbo_stream.replace(
        "leader_settlement_invoice_form",
        partial: "event/participations/popover_create_course_leader_invoice",
        locals: { invoice_form: invoice_form }
      ), status: :unprocessable_entity
    end
  end

  def render_pdf_in_background
    with_async_download_cookie(:pdf, :leader_settlement) do |filename|
      Export::LeaderSettlementExportJob.new(current_person.id, 
                                            Event::Participation.first.id, # TODO
                                            @invoice_form.iban, 
                                            filename: filename).enqueue!
    end
  end

  private

  def assign_attributes
    invoice_form.attributes = invoice_form_params
  end

  def invoice_form_params
    params
      .require(:event_courses_leader_settlement_invoice)
      .permit(:actual_days, :iban).merge(course: event)
  end

  def invoice_form = @invoice_form ||= Event::Courses::LeaderSettlementInvoice.new

  def group = @group ||= Group.find(params[:group_id])

  def event = @event ||= Event::Course.find(params[:event_id])
end
