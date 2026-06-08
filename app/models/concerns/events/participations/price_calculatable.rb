# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Participations::PriceCalculatable
  extend ActiveSupport::Concern

  included do
    delegate :sac_membership_active?, :sac_membership_active_in?, to: :person
  end

  def signup_price
    event.send(signup_price_category)
  end

  def signup_price_category(subsidy: false)
    event.course? ? course_price_category(subsidy) : tour_price_category
  end

  def signup_subsidy
    (subsidizable? && subsidy?) ? event.price_subsidized : 0
  end

  def subsidizable?
    event.course? && event.price_subsidized.present? && sac_membership_active?
  end

  def subsidy?
    is_a?(Event::Participation) ? subsidy.present? : participation.subsidy.present?
  end

  private

  def course_price_category(subsidy)
    if sac_membership_active?
      subsidy ? :price_subsidized : :price_member
    else
      :price_regular
    end
  end

  def tour_price_category
    if sac_membership_active?
      sac_membership_active_in?(event.groups.first) ? :price_special : :price_member
    else
      :price_regular
    end
  end
end
