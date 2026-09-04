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

  helper_method :group, :events, :event, :event_filter

  def index
    preload_assocs
    if turbo_frame_request?
      render partial: "list"
    else
      render :index
    end
  end

  def show
    preload_tour_assocs([event]) if event.tour?
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
    @leaders = preload_leaders
  end

  def preload_essentials(klass)
    klass.list.without_deleted.includes(:translations)
  end

  def preload_leaders
    Person
      .select(:id, :first_name, :last_name, :nickname, :company, :company_name)
      .joins(event_participations: [:roles, event: [:dates, :groups]])
      .where(
        event_participations: {active: true},
        event_roles: {type: leader_roles.map(&:sti_name)},
        groups: {id: group.id},
        event_dates: {start_at: leader_date_range}
      )
      .distinct
      .order_by_name
  end

  def leader_roles
    Events::Filter::Leader.new(:leader, {}).leader_roles
  end

  def leader_date_range
    today = Time.zone.today
    Date.new(today.year, 1, 1)..Date.new(today.year + 1, 12, 31)
  end

  def preload_assocs
    return unless group

    preload_event_assocs
    preload_tour_assocs(events.filter(&:tour?))
  end

  def preload_event_assocs
  end

  def preload_tour_assocs(tours)
    ActiveRecord::Associations::Preloader.new(
      records: tours,
      associations: [
        {activities: [:translations,
          {parent: :icon_attachment,
           technical_requirement: :translations}]},
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
    @events ||= event_filter.entries.preload(:contact)
  end

  def group
    @group ||= params[:group_id].present? ? Group.find(params[:group_id]) : nil
  end

  def event
    @event ||= event_filter.entries.find(params[:event_id])
  end
end
