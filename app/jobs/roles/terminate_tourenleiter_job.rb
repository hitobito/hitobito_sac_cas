# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Roles::TerminateTourenleiterJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    Group::SektionsTourenUndKurse::Tourenleiter
      .left_joins(person: :qualifications)
      .where(qualifications: {finish_at: [nil, [...Time.zone.today]]})
      .update_all(deleted_at: Time.zone.yesterday.end_of_day)
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
