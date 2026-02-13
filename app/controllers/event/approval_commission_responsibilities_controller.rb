# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::ApprovalCommissionResponsibilitiesController < ApplicationController
  before_action :authorize_action
  helper_method :group, :freigabe_komitees, :form

  def edit
    @form = form
    @group = group
  end

  def update
    assign_attributes

    if form.valid? && form.save!
      redirect_to tour_group_events_path(group), notice: success_message
    else
      render :edit, status: :unprocessable_entity, locals: {form: @form}
    end
  end

  private

  def assign_attributes
    form.assign_attributes(event_approval_commission_responsibility_form_params)
  end

  def event_approval_commission_responsibility_form_params
    params
      .require(:event_approval_commission_responsibility_form)
      .permit(event_approval_commission_responsibilities_attributes: [:id, :target_group_id,
        :discipline_id, :subito, :freigabe_komitee_id])
  end

  def success_message(action: action_name)
    t("crud.#{action}.flash.success",
      model: Event::ApprovalCommissionResponsibility.model_name.human(count: 2))
  end

  def permitted_params
    params.require(:event_approval_commission_responsibilities).permit!
  end

  def authorize_action
    authorize!(:update, group)
  end

  def freigabe_komitees
    @freigabe_komitees ||= Group::FreigabeKomitee.where(layer_group_id: group.id).order(:name)
  end

  def form = @form ||= Event::ApprovalCommissionResponsibilityForm.new(group:)

  def group = @group ||= Group.find(params[:group_id])
end
