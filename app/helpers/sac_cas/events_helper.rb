# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth

module SacCas::EventsHelper
  def format_event_unconfirmed_count(event)
    if event.unconfirmed_count.positive? && can?(:application_market, event)
      badge(event.unconfirmed_count, :secondary)
    end
  end
end
