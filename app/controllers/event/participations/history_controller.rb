# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Participations::HistoryController < ApplicationController
  before_action :authorize_action
  before_action :participation, :event,
    :group, :load_recent_trainings_and_participations, only: [:index]

  decorates :group, :event, :participation

  def participation
    @participation ||= Event::Participation.find(params[:id])
  end

  def event
    @event ||= Event.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def load_recent_trainings_and_participations
    history = Participations::History.new(participation.person)
    @recent_trainings = history.recent_trainings
    @recent_tours = history.recent_tours
  end

  def authorize_action
    authorize!(:show_detail, participation)
  end
end
