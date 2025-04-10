#  Copyright (c) 2025, SAC CAS. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ListsController
  extend ActiveSupport::Concern

  prepended do
    skip_authorize_resource only: [:tours]
  end

  def tours
    authorize!(:list_available, Event::Tour)

    @nav_left = "tours"
    @tours = grouped(upcoming_user_tours)
  end

  private

  def upcoming_user_tours(states = %w[published])
    Event::Tour
      .upcoming
      .where(state: states)
      .in_hierarchy(current_user)
      .includes(:dates, :groups)
      .order("event_dates.start_at ASC")
  end

  def upcoming_user_events
    super.where("events.type != ? OR events.type IS NULL", Event::Tour.sti_name)
  end
end
