# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::ApplicationMarketHelper
  def application_market_application_link(group, event, participation)
    super unless event.canceled?
  end

  def application_market_participant_link(group, event, participation)
    super unless event.canceled?
  end
end
