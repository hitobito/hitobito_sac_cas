# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe BackupMitgliederExport do
  let(:group) { groups(:bluemlisalp) }
  let(:sftp) { double(:sftp) }

  let(:export) { BackupMitgliederExport.new(group, sftp) }

  it 'tries to upload csv for group' do
    csv_expectation = SacCas::Export::MitgliederExportJob.new(nil, group.id).data
    root_folder_path_expectation = "sektionen/"
    folder_path_expectation = "sektionen/1650/"
    file_path_expectation = "sektionen/1650/Adressen_00001650.csv"

    expect(sftp).to receive(:directory?).with(root_folder_path_expectation).and_return(true)
    expect(sftp).to receive(:directory?).with(folder_path_expectation).and_return(true)
    expect(sftp).to receive(:upload_file).with(csv_expectation, file_path_expectation)

    export.call
  end

  it 'tries to upload csv for group and create directories if not present' do
    csv_expectation = SacCas::Export::MitgliederExportJob.new(nil, group.id).data
    root_folder_path_expectation = "sektionen/"
    folder_path_expectation = "sektionen/1650/"
    file_path_expectation = "sektionen/1650/Adressen_00001650.csv"

    expect(sftp).to receive(:directory?).with(root_folder_path_expectation).and_return(false)
    expect(sftp).to receive(:create_remote_dir).with(root_folder_path_expectation)
    expect(sftp).to receive(:directory?).with(folder_path_expectation).and_return(false)
    expect(sftp).to receive(:create_remote_dir).with(folder_path_expectation)
    expect(sftp).to receive(:upload_file).with(csv_expectation, file_path_expectation)

    export.call
  end
end
