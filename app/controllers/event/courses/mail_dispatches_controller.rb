# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Courses::MailDispatchesController < ApplicationController
  def create
    authorize!(:create, course)

    unless course.link_survey.nil?
      
    else
      redirect_to group_event_path(group, course), flash: {alert: t(".warning")}
    end
  end

  private

  def group = @group ||= Group.find(params[:group_id])
  
  def course = @course ||= Event::Course.find(params[:event_id])
end
