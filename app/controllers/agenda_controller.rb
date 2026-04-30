# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AgendaController < ApplicationController
  skip_before_action :authenticate_person!
  skip_authorization_check

  layout "agenda"

  helper_method :group, :events, :event

  def index
    init_filter_values
  end

  def show
  end

  private

  def init_filter_values
    set_date_range
    set_event_type
  end

  def set_date_range
    params[:filters] ||= {}
    params[:filters][:date_range] ||= {
      since: I18n.l(Time.zone.today.to_date)
    }
  end

  def set_event_type
    params[:filters] ||= {}
    params[:filters][:type] ||= {types: ["Event::Tour"]}
  end

  def events = @events ||= event_filter.entries.joins(:dates).order(dates: {start_at: :asc})

  def event_filter = @event_filter ||= Events::Filter::AgendaList.new(nil, params)

  def group = @group ||= Group.find(params[:group_id])

  def event = @event ||= events.find(params[:event_id])
end
