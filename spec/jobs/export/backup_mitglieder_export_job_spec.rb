# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::BackupMitgliederExportJob do
  subject(:job) do
    described_class.new(group.id).tap do
      allow(_1).to receive(:sftp).and_return(sftp)
    end
  end

  let(:group) { groups(:bluemlisalp) }
  let(:sftp) { double(:sftp) }

  context "logging" do
    let(:notifications) { Hash.new { |h, k| h[k] = [] } }

    def subscribe
      callback = lambda do |name, started, finished, unique_id, payload|
        notifications[name] <<
          OpenStruct.new(name: name, started: started, finished: finished, unique_id: unique_id, payload: payload)
      end
      ActiveSupport::Notifications.subscribed(callback, /\w+\.background_job/) do
        yield
      end
    end

    def run_job(payload_object)
      payload_object.enqueue!.tap do |job_instance|
        Delayed::Worker.new.run(job_instance)
      end
    end

    it "logs any type of error raised and continues" do
      exporter = double
      allow(exporter).to receive(:call)

      error = Sftp::ConnectionError.new("permission denied")

      expect(sftp).to receive(:upload_file).and_raise(error)

      job = subscribe { run_job(subject) }

      expect(notifications.keys).to match_array [
        "job_started.background_job",
        "job_finished.background_job"
      ]

      expect(notifications["job_started.background_job"]).to have(1).item
      expect(notifications["job_finished.background_job"]).to have(1).item

      started_attrs = notifications["job_started.background_job"].first[:payload]
      expect(started_attrs).to match(
        job_id: job.id,
        job_name: described_class.name,
        group_id: nil,
        started_at: an_instance_of(ActiveSupport::TimeWithZone),
        attempt: 0
      )

      finished_attrs = notifications["job_finished.background_job"].first[:payload]
      expect(finished_attrs).to match(
        job_id: job.id,
        job_name: described_class.name,
        group_id: nil,
        finished_at: an_instance_of(ActiveSupport::TimeWithZone),
        status: "error",
        payload: {error: an_instance_of(Hash)},
        attempt: 0
      )
      expect(finished_attrs[:payload][:error][:message]).to match(/permission denied/)
    end
  end

  context "perform" do
    it "tries to upload csv for group" do
      csv_expectation = SacCas::Export::MitgliederExportJob.new(nil, group.id).data
      file_path_expectation = "1650/Adressen_00001650.csv"

      expect(sftp).to receive(:upload_file).with(csv_expectation, file_path_expectation)

      job.perform
    end

    context "for sektion" do
      let(:group) { groups(:bluemlisalp) }

      it "writes file to sektion.id folder" do
        file_path_expectation = start_with("#{group.navision_id}/")
        expect(sftp).to receive(:upload_file).with(anything, file_path_expectation)

        job.perform
      end
    end

    context "for ortsgruppe" do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

      it "writes file to sektion.id folder" do
        file_path_expectation = start_with("#{group.parent.navision_id}/")
        expect(sftp).to receive(:upload_file).with(anything, file_path_expectation)

        job.perform
      end
    end
  end
end
