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
  end

  def perform
    # upload the file to all file_paths
    file_paths.each do |file_path|
      sftp.upload_file(csv, file_path)
    end
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

  # returns both paths in group directory AND sektion directory unless they are identical
  def file_paths
    [
      "#{sektion.navision_id}/Adressen_#{group.id_padded}.csv",
      "#{group.navision_id}/Adressen_#{group.id_padded}.csv"
    ].uniq
  end

  def sektion
    group.is_a?(Group::Ortsgruppe) ? group.parent : group
  end

  def group
    @group ||= Group.find(@group_id)
  end
end
