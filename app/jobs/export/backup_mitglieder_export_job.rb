# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::BackupMitgliederExportJob < BaseJob
  self.parameters = [:group_id]
  self.use_background_job_logging = true

  def initialize(group_id)
    super()
    @group_id = group_id
    @errors = []
  end

  def perform
    sftp.upload_file(csv, file_path)
  rescue => e
    error(self, e, group: group)
    @errors << [@group_id, e]
  end

  def log_results
    {
      errors: @errors
    }
  end

  private

  def csv
    @csv ||= begin
               user_id = nil
               SacCas::Export::MitgliederExportJob.new(user_id, @group_id).data
             end
  end

  def sftp
    @sftp ||= Sftp.new(sftp_config)
  end

  def sftp_config
    Settings.sftp.config
  end

  def file_path
    "sektionen/#{group.navision_id}/Adressen_#{group.navision_id_padded}.csv"
  end

  def group
    @group ||= Group.find(@group_id)
  end
end
