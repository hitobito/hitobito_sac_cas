# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Tours::ApprovalsController < ApplicationController
  PERMITTED_ATTRS = [
    :internal_comment,
    komitee_approvals_attributes: [[
      :freigabe_komitee_id,
      approval_kind_approvals_attributes: [[:approval_kind_id, :checked]]
    ]]
  ]

  before_action :authorize_action

  decorates :group, :event

  helper_method :entry

  def edit
    form.pre_check_approvable
  end

  def update
    form.attributes = permitted_attrs
    if form.save(params[:button])
      flash[:notice] ||= t("event.tours.approvals.update.#{flash_notice_key}")
      redirect_to group_event_path(group, event)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def permitted_attrs
    params.require(:event_tour_approval_form).permit(PERMITTED_ATTRS)
  end

  def flash_notice_key
    if form.changed_approvals.present?
      event.state
    else
      "success"
    end
  end

  def form = @form ||= Event::Tour::ApprovalForm.new(event, current_user)
  alias_method :entry, :form

  def event = @event ||= group.events.find(params[:event_id])

  def group = @group ||= Group.find(params[:group_id])

  def authorize_action = authorize!(:update, event)
end
