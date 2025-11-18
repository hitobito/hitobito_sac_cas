# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Roles::TerminateNeuanmeldungenNvJob < RecurringJob
  run_every 1.day

  ROLE_TYPES = SacCas::NEUANMELDUNG_NV_STAMMSEKTION_ROLES +
    SacCas::NEUANMELDUNG_NV_ZUSATZSEKTION_ROLES

  private

  def perform_internal
    Role
      .where(type: ROLE_TYPES.map(&:sti_name), start_on: ..4.months.ago)
      .update_all(end_on: Time.zone.yesterday)
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
