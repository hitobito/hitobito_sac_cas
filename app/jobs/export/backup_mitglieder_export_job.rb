# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::BackupMitgliederExportJob < RecurringJob

  run_every 1.day
  self.use_background_job_logging = true

  ROLE_TYPES_TO_BACKUP = [::Group::Sektion, ::Group::Ortsgruppe].freeze

  def initialize
    super
    @errors = []
  end

  def perform_internal
    relevant_groups.find_each do |group|
      BackupMitgliederExport.new(group, sftp).call
    rescue StandardError => e
      error(self, e, group: group)
      @errors << [group.id, e]
      next
    end
  end

  def log_results
    {
      errors: @errors
    }
  end

  private

  def relevant_groups
    Group.where(type: ROLE_TYPES_TO_BACKUP.map(&:sti_name))
  end

  def sftp
    @sftp ||= Sftp.new(sftp_config)
  end

  def sftp_config
    Settings.sftp.config
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
