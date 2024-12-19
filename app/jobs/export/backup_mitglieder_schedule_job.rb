# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::BackupMitgliederScheduleJob < RecurringJob
  run_every 1.day

  ROLE_TYPES_TO_BACKUP = [Group::Sektion, Group::Ortsgruppe].map(&:sti_name)

  # Job is temporarily disabled (https://github.com/hitobito/hitobito_sac_cas/issues/1426)
  # When re-enabling, also un-skip the corresponding specs.
  def perform_internal_DISABLED
    relevant_groups.find_each do |group|
      Export::BackupMitgliederExportJob.new(group.id).enqueue!
    end
  end

  private

  def relevant_groups
    Group.where(type: ROLE_TYPES_TO_BACKUP)
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
