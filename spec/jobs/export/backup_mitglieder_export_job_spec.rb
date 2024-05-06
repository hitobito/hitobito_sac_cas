# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Export::BackupMitgliederExportJob do
  subject(:job) { described_class.new }
  let(:relevant_groups) { Group.where(type: [::Group::Sektion, ::Group::Ortsgruppe]) }

  context 'rescheduling' do
    it 'reschedules for tomorrow  at 5 minutes past midnight' do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%BackupMitgliederExportJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context 'perform' do
    it 'only iterates over relevant groups' do
      exporter = double
      allow(exporter).to receive(:call)

      relevant_groups.each do |group|
        expect(BackupMitgliederExport).to receive(:new)
          .with(group, an_instance_of(Sftp))
          .and_return(exporter)

      end

      job.perform
    end
  end

  context 'logging' do
    let(:notifications) { Hash.new {|h, k| h[k] = [] } }

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

    it 'logs any type of error raised and continues' do
      exporter = double
      allow(exporter).to receive(:call)

      error_group = relevant_groups.first

      error = Sftp::ConnectionError.new('permission denied')

      expect(BackupMitgliederExport).to receive(:new)
                                    .with(error_group, an_instance_of(Sftp))
                                    .and_raise(error)
      expect(job).to receive(:error).with(job, error, group: error_group)
      
      (relevant_groups - [error_group]).each do |group|
        expect(BackupMitgliederExport).to receive(:new)
          .with(group, an_instance_of(Sftp))
          .and_return(exporter)
      end

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
        status: 'success',
        payload: { errors: [[error_group.id, error]] },
        attempt: 0
      )
    end
  end
end
