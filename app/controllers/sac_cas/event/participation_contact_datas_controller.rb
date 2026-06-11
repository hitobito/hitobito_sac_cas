#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipationContactDatasController
  extend ActiveSupport::Concern

  prepended do
    before_action :assert_price_category_possible
  end

  private

  def assert_price_category_possible
    return if entry.price_category_may_apply?

    possible_categories = event.possible_price_categories.map {
      Event::Tour.human_attribute_name(_1)
    }.join(", ")

    flash[:alert] = I18n.t(
      "event.participation_contact_datas.flash.price_category_not_possible",
      possible_categories: possible_categories
    )

    redirect_to group_event_path(group, event)
  end
end
