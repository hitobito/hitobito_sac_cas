#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Courses::LeaderSettlementPdfsController < ApplicationController
  include AsyncDownload

  before_action :authorize_class

  def create
    @group = group
    @event = event
    assign_attributes

    if entry.valid?
      participation.update!(actual_days: entry.actual_days) && render_pdf_in_background
    else
      rerender_form(:unprocessable_entity)
    end
  end

  private

  def render_pdf_in_background
    with_async_download_cookie(:pdf, "Kurskaderabrechnung Kurs #{event.number}",
      redirection_target: group_event_participation_path(group, event, participation)) do |filename|
      Export::LeaderSettlementExportJob.new(current_person.id,
        participation.id,
        entry.iban,
        filename: filename).enqueue!
    end
  end

  def rerender_form(status)
    render turbo_stream: turbo_stream.replace(
      "leader_settlement_form",
      partial: "event/participations/popover_create_course_leader_settlement",
      locals: {entry: entry}
    ), status: status
  end

  def assign_attributes
    entry.attributes = leader_settlement_form_params
  end

  def leader_settlement_form_params
    params
      .require(:event_courses_leader_settlement_form)
      .permit(:actual_days, :iban).merge(course: event)
  end

  def authorize_class
    authorize!(:leader_settlement, participation)
  end

  def entry = @entry ||= Event::Courses::LeaderSettlementForm.new

  def group = @group ||= Group.find(params[:group_id])

  def event = @event ||= Event::Course.find(params[:event_id])

  def participation = @participation ||= Event::Participation.find(params[:participation_id])
end
