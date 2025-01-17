# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::EventParticipationHelper
  def format_event_participation_price(entry)
    format_event_price(entry.price_category, entry.price) if entry.price.present?
  end

  def format_event_price(attr, price)
    [Event::Course.human_attribute_name(attr), I18n.t("global.currency"), sprintf("%.2f", price)].join(" ")
  end

  def event_participation_cancellation_cost(entry)
    Invoices::Abacus::CourseAnnulationCost.new(entry).position_description_and_amount_cancelled.last
  end
end
