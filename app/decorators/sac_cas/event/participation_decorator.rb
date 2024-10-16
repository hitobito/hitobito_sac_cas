# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationDecorator
  extend ActiveSupport::Concern
  include SacCas::EventParticipationHelper

  def to_s(*)
    to_s_without_state(*)
  end

  def event_prices
    prices = present_event_prices.map { |attr, price| [format_event_price(attr, price), attr] }
    prices.unshift(former_price_select_option) if event_price_changed?
    prices << [t("no_price_select"), nil] if present_event_prices.empty? || event_leader?

    [prices, event_price_changed? ? {selected: "former"} : {}]
  end

  private

  def present_event_prices
    @present_event_prices ||= event.attributes.slice(*Event::Course::PRICE_ATTRIBUTES.map(&:to_s)).compact
  end

  def event_price_changed?
    @price_changed ||= model.persisted? && present_event_prices[price_category] != price
  end

  def former_price_select_option
    [t("former_price_select", price_label: format_event_price(price_category, price)), "former"]
  end

  def event_leader?
    roles.exists?(type: SacCas::EVENT_LEADER_ROLES.map(&:sti_name))
  end

  def t(key, **)
    I18n.t(key, scope: "event.participations.fields_sac_cas", **)
  end
end
