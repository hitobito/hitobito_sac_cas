# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::CornercardApplicationsScheduleJob < RecurringJob
  run_every 1.week

  def perform_internal
    Export::CornercardApplicationsJob.new.enqueue!
  end

  private

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
