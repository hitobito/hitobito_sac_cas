# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::ApplicationMarketHelper
  def application_market_application_link(p)
    link_to(icon("arrow-left"),
      participant_group_event_application_market_path(@group, @event, p), # rubocop:disable Rails/HelperInstanceVariable
      remote: true,
      method: :put,
      data: {confirm: t(".add_participant_confirm")})
  end

  def application_market_participant_link(p)
    link_to(icon("arrow-right"),
      participant_group_event_application_market_path(@group, @event, p), # rubocop:disable Rails/HelperInstanceVariable
      remote: true,
      method: :delete,
      data: {confirm: t(".remove_participant_confirm")})
  end
end
