# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::CornercardApplicationsJob do
  let(:sftp) { double(:sftp) }
  let(:config) { double(:config, folder: "/outbox/sac") }
  let(:person) do
    Person.create!(
      first_name: "Max",
      last_name: "Muster",
      email: "max@example.com",
      birthday: Date.new(1990, 1, 15),
      gender: "m"
    )
  end

  before do
    allow(Settings).to receive(:cornercard).and_return(config)
    allow(Sftp).to receive(:new).and_return(sftp)
    allow(sftp).to receive(:upload_file)
  end

  describe "#perform" do
    it "uploads xlsx and stamps uploads when pending exist" do
      upload = person.create_cornercard_upload!

      described_class.new.perform

      expect(sftp).to have_received(:upload_file)
      expect(upload.reload.uploaded_at).to be_present
    end

    it "does nothing when no pending uploads exist" do
      described_class.new.perform

      expect(sftp).not_to have_received(:upload_file)
    end

    it "creates a log entry" do
      person.create_cornercard_upload!

      described_class.new.perform

      log = HitobitoLogEntry.last
      expect(log.category).to eq("cornercard")
      expect(log.level).to eq("info")
      expect(log.message).to include("1 Anträge")
    end

    it "uses correct file path with date" do
      person.create_cornercard_upload!
      date = Date.current.strftime("%Y-%m-%d")

      described_class.new.perform

      expect(sftp).to have_received(:upload_file)
        .with(anything, "/outbox/sac/sac-cornercard-#{date}.xlsx")
    end
  end
end
