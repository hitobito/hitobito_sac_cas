# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class BackupMitgliederExport

  def initialize(group, sftp)
    @group = group
    @sftp = sftp
  end

  def call
    @sftp.create_remote_dir(root_folder_path) unless @sftp.directory?(root_folder_path)
    @sftp.create_remote_dir(folder_path) unless @sftp.directory?(folder_path)

    @sftp.upload_file(csv, file_path)
  end

  private

  def csv
    @csv ||= begin
               user_id = nil
               SacCas::Export::MitgliederExportJob.new(user_id, @group.id).data
             end
  end

  def file_path
    "#{folder_path}Adressen_#{@group.navision_id_padded}.csv"
  end

  def folder_path
    "#{root_folder_path}#{@group.navision_id}/"
  end

  def root_folder_path
    'sektionen/'
  end

end
