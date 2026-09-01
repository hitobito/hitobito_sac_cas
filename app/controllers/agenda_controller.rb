# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AgendaController < ApplicationController
  include Rememberable

  skip_before_action :authenticate_person!
  skip_authorization_check

  self.remember_params = [:filters]

  before_action :set_default_date_range_filter, only: :index, unless: :turbo_frame_request?
  # Needed on every request, not just full page loads: the results partial
  # (rendered for turbo-frame requests too) uses these to label activity/
  # target-group/... filter chips and technical-requirement chips.
  before_action :preload_filter_options, only: :index

  layout -> { turbo_frame_request? ? false : "agenda" }

  helper_method :group, :events, :event, :event_filter, :event_leaders

  def index
    preload_assocs
    if turbo_frame_request?
      render partial: "list"
    else
      render :index
    end
  end

  def show
  end

  private

  def set_default_date_range_filter
    params[:filters] ||= {}
    params[:filters][:date_range] ||= {since: I18n.l(Time.zone.today.to_date)}
  end

  def preload_filter_options
    return unless group

    @target_groups = preload_essentials(Event::TargetGroup)
    @activities = preload_essentials(Event::Activity).includes(:technical_requirement)
    @technical_requirements = preload_essentials(Event::TechnicalRequirement)
    @fitness_requirements = preload_essentials(Event::FitnessRequirement)
    @traits = preload_essentials(Event::Trait)
    @leaders = AgendaLeaders.filter_leaders(group)
  end

  def preload_essentials(klass)
    klass.list.without_deleted.includes(:translations)
  end

  def preload_assocs
    return unless group

    load_event_leaders(events)
    preload_tour_assocs
  end

  def load_event_leaders(events)
    @event_leaders = (@event_leaders || {}).merge(AgendaLeaders.new(events).to_h)
  end

  # used for index and for show
  def event_leaders(event)
    load_event_leaders([event]) unless @event_leaders&.key?(event.id)

    @event_leaders[event.id]
  end

  def preload_tour_assocs
    tours = events.filter(&:tour?)
    ActiveRecord::Associations::Preloader.new(
      records: tours,
      associations: [
        {activities: [:translations, :parent, :technical_requirement]},
        {target_groups: :translations},
        {technical_requirements: :translations},
        {fitness_requirement: :translations},
        {traits: :translations}
      ]
    ).call
  end

  def event_filter
    @event_filter ||= Events::Filter::AgendaList.new(nil, params)
  end

  def events
    @events ||= event_filter.entries.to_a
  end

  def group
    @group ||= params[:group_id].present? ? Group.find(params[:group_id]) : nil
  end

  def event
    @event ||= event_filter.entries.find(params[:event_id])
  end
end
