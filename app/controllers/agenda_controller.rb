# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AgendaController < ApplicationController
  skip_before_action :authenticate_person!
  skip_authorization_check

  before_action :set_default_type_filter, only: :index
  before_action :set_default_date_range_filter, only: :index, unless: :turbo_frame_request?
  before_action :preload_filter_select_options, only: :index, unless: :turbo_frame_request?

  layout -> { turbo_frame_request? ? false : "agenda" }

  helper_method :group, :events, :event, :event_filter

  def index
    if turbo_frame_request?
      render partial: "agenda/list", locals: {events: events}
    else
      render :index
    end
  end

  def show
  end

  private

  def set_default_type_filter
    params[:filters] ||= {}
    params[:filters][:type] ||= {types: [Event::Tour.sti_name]}
  end

  def set_default_date_range_filter
    params[:filters] ||= {}
    params[:filters][:date_range] ||= {since: I18n.l(Time.zone.today.to_date)}
  end

  def preload_filter_select_options
    @target_groups = Event::TargetGroup.list.without_deleted
    @activities = Event::Activity.list.without_deleted
    @technical_requirements = Event::TechnicalRequirement.list.without_deleted
    @fitness_requirements = Event::FitnessRequirement.list.without_deleted
  end

  def event_filter
    @event_filter ||= Events::Filter::AgendaList.new(nil, params)
  end

  def events = @events ||= event_filter.entries.joins(:dates).order(dates: {start_at: :asc})

  def group = @group ||= params[:group_id].present? ? Group.find(params[:group_id]) : nil

  def event = @event ||= event_filter.entries.find(params[:event_id])
end
