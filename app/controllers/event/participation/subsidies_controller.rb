# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Participation::SubsidiesController < ApplicationController
  layout 'course_signup'

  attr_reader :entry
  helper_method :particpation_path, :entry
  before_action :find_and_authorize

  def new
    entry.subsidy = params.dig(:event_participation, :subsidy)
  end

  def update
    entry.update(subsidy: params.dig(:event_participation, :subsidy))
    redirect_to particpation_path
  end

  private

  def find_and_authorize
    @entry = Event::Participation.find(params[:participation_id])
    authorize!(:update, entry)
  end

  def particpation_path
    group_event_participation_path(
      group_id: params[:group_id],
      event_id: params[:event_id],
      id: params[:participation_id]
    )
  end
end
