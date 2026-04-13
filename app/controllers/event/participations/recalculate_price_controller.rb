# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# Recalculate the price of a participation based on passed params
class Event::Participations::RecalculatePriceController < ApplicationController
  before_action :authorize_action
  before_action :participation, :event, :group

  def index
    if price_category?
      render_price_category_price
    elsif participation.present? && reference_date.present?
      render_annulation_price
    else
      render json: {error: "Invalid query param", status: :bad_request}, status: :bad_request
    end
  end

  private

  def render_price_category_price
    if event.class::PRICE_ATTRIBUTES.include?(price_category.to_sym)
      render json: {value: "%.2f" % event.send(price_category)}
    elsif price_category.blank?
      render json: {value: "%.2f" % BigDecimal("0.00")}
    else
      render json: {errors: "Invalid price category"}, status: :unprocessable_content
    end
  end

  def render_annulation_price
    participation.canceled_at = reference_date

    if participation.canceled_at?
      render json: {value:
        "%.2f" % Invoices::Abacus::CourseAnnulationCost.new(participation).amount_cancelled}
    else
      render json: {errors: "Invalid reference date"}, status: :unprocessable_content
    end
  end

  def price_category?
    params.dig(:event_participation)&.has_key?(:price_category) ||
      params.dig(:event_participation_invoice_form)&.has_key?(:price_category)
  end

  def price_category
    @price_category ||= params.dig(:event_participation, :price_category) ||
      params.dig(:event_participation_invoice_form, :price_category)
  end

  def reference_date
    @reference_date ||= params.dig(:event_participation_invoice_form, :reference_date)
  end

  def authorize_action
    return authorize!(:create, Event::Participation) if participation.nil?

    if params.dig(:event_participation_invoice_form)
      raise CanCan::AccessDenied if participation.roles.exists?(type: Event::Course::LEADER_ROLES)

      authorize!(:summon, participation)
    else
      authorize!(:update_full, participation)
    end
  end

  def participation = @participation ||= Event::Participation.find_by(id: params[:id])

  def event = @event ||= Event.find(params[:event_id])

  def group = @group ||= Group.find(params[:group_id])
end
