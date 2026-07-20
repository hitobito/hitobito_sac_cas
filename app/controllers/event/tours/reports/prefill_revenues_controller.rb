# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tours::Reports::PrefillRevenuesController < ApplicationController
  before_action :authorize_action, :assert_event_reportable

  def show
    render json: revenue_rows
  end

  private

  def revenue_rows
    participation_counts.filter_map do |(price_category, price), count|
      next if price_category.nil? || (!count.zero? && !price&.positive?)

      {
        description: Event::Tour.human_attribute_name(price_category),
        count: count,
        amount: format("%.2f", price)
      }
    end
  end

  def participation_counts
    @participation_counts ||= begin
      counts = event.participations.group(:price_category, :price).count

      (Event::Tour::PRICE_ATTRIBUTES.map(&:to_s) - counts.keys.map(&:first)).each do |category|
        counts[[category, 0]] = 0
      end

      counts
    end
  end

  def event = @event ||= group.events.find(params[:event_id])

  def group = @group ||= Group.find(params[:group_id])

  def authorize_action
    authorize!(:update, event)
  end

  def assert_event_reportable
    raise CanCan::AccessDenied unless event.reportable?
  end
end
