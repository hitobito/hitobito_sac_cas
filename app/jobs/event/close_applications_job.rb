# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::CloseApplicationsJob < RecurringJob
  run_every 1.day

  def perform_internal
    Event::Course
      .where(state: %w(application_open application_paused))
      .where(application_closing_at: [...Time.zone.today])
      .update_all(state: :application_closed)
  end
end
