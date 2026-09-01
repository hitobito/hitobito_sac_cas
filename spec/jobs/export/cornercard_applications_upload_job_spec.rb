# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::CornercardApplicationsUploadJob do
  let(:sftp) { double(:sftp) }
  let(:config) { double(:config) }
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
    allow(Settings.cornercard).to receive(:config).and_return(config)
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

    it "does nothing when config is missing" do
      allow(Settings.cornercard).to receive(:config).and_return(nil)
      person.create_cornercard_upload!

      described_class.new.perform

      expect(sftp).not_to have_received(:upload_file)
    end

    it "creates a log entry with person IDs" do
      person.create_cornercard_upload!

      described_class.new.perform

      log = HitobitoLogEntry.last
      expect(log.category).to eq("cornercard")
      expect(log.level).to eq("info")
      expect(log.message).to include("1 Anträge")
      expect(JSON.parse(log.payload)).to include(person.id)
    end

    it "uses correct file path with timestamp" do
      person.create_cornercard_upload!

      described_class.new.perform

      expected = "cornercard_antraege_#{Time.current.strftime("%Y%m%d_%H%M")}.xlsx"
      expect(sftp).to have_received(:upload_file).with(anything, expected)
    end
  end

  describe "is a recurring job and" do
    it "has the proper superclass" do
      expect(described_class.new).to be_a(RecurringJob)
    end

    it "runs weekly" do
      expect(described_class.interval).to eq 1.week
    end

    it "schedules at 00:10 after the next weekly boundary" do
      travel_to(Time.zone.local(2026, 3, 18, 14, 30)) do
        job = described_class.new
        next_run = job.send(:next_run)

        expect(next_run).to eq 1.week.from_now.midnight + 10.minutes
        expect(next_run).to eq Time.zone.parse("2026-03-25 00:10:00")
      end
    end

    it "always lands on 00:10" do
      travel_to(Time.zone.local(2026, 6, 1, 23, 59)) do
        job = described_class.new
        next_run = job.send(:next_run)

        expect(next_run.hour).to eq 0
        expect(next_run.min).to eq 10
      end
    end
  end
end
