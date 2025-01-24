# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Sftp do
  let(:config) do
    Config::Options.new(host: "sftp.local",
      user: "hitobito",
      password: "password",
      private_key: "private key",
      port: 22)
  end
  let(:session) { instance_double("Net::SFTP::Session", connect!: true) }

  subject(:sftp) { Sftp.new(config) }

  before { allow(sftp).to receive(:server_version).and_return("unknown") }

  context "with password" do
    before { config.delete_field!(:private_key) }

    it "creates connection with password credential" do
      expect(::Net::SFTP).to receive(:start)
        .with("sftp.local", "hitobito", {password: "password",
                                                           non_interactive: true,
                                                           port: 22})
        .and_return(session)

      subject.send(:connection)
    end
  end

  context "with private key" do
    before { config.delete_field!(:password) }

    it "creates connection with private key" do
      expect(::Net::SFTP).to receive(:start)
        .with("sftp.local", "hitobito", {key_data: ["private key"],
                                                          non_interactive: true,
                                                          port: 22})
        .and_return(session)

      subject.send(:connection)
    end
  end

  context "with private key and password" do
    it "creates connection with private key" do
      expect(::Net::SFTP).to receive(:start)
        .with("sftp.local", "hitobito", {key_data: ["private key"],
                                                           non_interactive: true,
                                                           port: 22})
        .and_return(session)

      subject.send(:connection)
    end
  end

  context "#upload_file" do
    it "tries to upload csv for group and does not create directories if present" do
      groups(:bluemlisalp)

      root_folder_path = "sektionen"
      folder_path = "sektionen/1650"
      file_path = "sektionen/1650/Adressen_00001650.csv"

      expect(sftp).to receive(:directory?).with(root_folder_path).and_return(true)
      expect(sftp).to receive(:directory?).with(folder_path).and_return(true)
      expect(sftp).to_not receive(:create_remote_dir)

      expect(::Net::SFTP).to receive(:start).and_return(session)
      expect(session).to receive(:upload!).with(be_a(String), file_path).and_return("handler")

      sftp.upload_file("data", file_path)
    end

    it "tries to upload csv for group and create directories if not present" do
      groups(:bluemlisalp)

      root_folder_path = "sektionen"
      folder_path = "sektionen/1650"
      file_path = "sektionen/1650/Adressen_00001650.csv"

      expect(sftp).to receive(:directory?).with(root_folder_path).and_return(false)
      expect(sftp).to receive(:create_remote_dir).with(root_folder_path)
      expect(sftp).to receive(:directory?).with(folder_path).and_return(false)
      expect(sftp).to receive(:create_remote_dir).with(folder_path)

      expect(::Net::SFTP).to receive(:start).and_return(session)
      expect(session).to receive(:upload!).with(be_a(String), file_path).and_return("handler")

      sftp.upload_file("data", file_path)
    end

    it "does not create directories on aws sftp" do
      allow(sftp).to receive(:server_version).and_return("AWS_SFTP")

      file_path = "sektionen/some/random/subdirs/1650/Adressen_00001650.csv"

      expect(sftp).to_not receive(:create_remote_dir)

      expect(::Net::SFTP).to receive(:start).and_return(session)
      expect(session).to receive(:upload!).with(be_a(String), file_path).and_return("handler")

      sftp.upload_file("data", file_path)
    end

    it "does not change encoding of data" do
      allow(sftp).to receive(:create_directories?).and_return(false)
      expect(::Net::SFTP).to receive(:start).and_return(session)

      original_payload = "thîs îs a ßtrïng în ISO-8859-1 énçødîñg".encode("ISO-8859-1")

      expect(session).to receive(:upload!) do |local_file_path, _remote_file_path|
        expect(File.binread(local_file_path).bytes).to eq original_payload.bytes
      end

      sftp.upload_file(original_payload, "/file/path")
    end
  end
end
