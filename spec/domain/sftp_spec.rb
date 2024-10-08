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
  let(:session) { instance_double("Net::SFTP::Session") }

  subject(:sftp) { Sftp.new(config) }

  context "with password" do
    before { config.delete_field!(:private_key) }

    it "creates connection with password credential" do
      expect(::Net::SFTP).to receive(:start)
        .with("sftp.local", "hitobito", {password: "password",
                                                           non_interactive: true,
                                                           port: 22})
        .and_return(session)
      expect(session).to receive(:connect!)

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
      expect(session).to receive(:connect!)

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
      expect(session).to receive(:connect!)

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
      expect(sftp).to_not receive(:create_remote_dir).with(root_folder_path)
      expect(sftp).to receive(:directory?).with(folder_path).and_return(true)
      expect(sftp).to_not receive(:create_remote_dir).with(folder_path)

      expect(::Net::SFTP).to receive(:start).and_return(session)
      expect(session).to receive(:connect!)
      expect(session).to receive(:open!).with(file_path, "w").and_return("handler")
      expect(session).to receive(:write!).with("handler", 0, "data")
      expect(session).to receive(:close)

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
      expect(session).to receive(:connect!)
      expect(session).to receive(:open!).with(file_path, "w").and_return("handler")
      expect(session).to receive(:write!).with("handler", 0, "data")
      expect(session).to receive(:close)

      sftp.upload_file("data", file_path)
    end
  end
end
