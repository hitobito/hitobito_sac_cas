# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module AgendaHelper
  def show_places_available_filter?(group)
    group.events.future.where(
      state: %w[published ready closed canceled],
      type: Event::Tour.sti_name,
      display_booking_info: true
    ).exists?
  end
end
