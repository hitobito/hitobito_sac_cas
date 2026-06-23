# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Tours::ReportsController < ApplicationController
  before_action :authorize_action, :assert_event_reportable

  decorates :group, :event

  helper_method :entry

  def edit
  end

  def update
    # form.attributes = permitted_attrs
    if form.save
      flash[:notice] ||= t("event.tours.reports.success_notice")
      redirect_to group_event_path(group, event)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def permitted_attrs
    # params
    #   .require(:event_tour_report_form)
    #   .permit()
  end

  def form = @form ||= Event::Tour::ReportForm.new(event.report || event.build_report)
  alias_method :entry, :form

  def event = @event ||= group.events.find(params[:event_id])

  def group = @group ||= Group.find(params[:group_id])

  def assert_event_reportable
    raise CanCan::AccessDenied unless event.reportable?
  end

  def authorize_action
    authorize!(:update, event)
  end
end
