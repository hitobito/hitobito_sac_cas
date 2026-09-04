# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::Abacus::TransmitPersonJob do
  let(:person) { people(:mitglied) }
  let(:other_person) { people(:familienmitglied) }
  let(:job) { described_class.new(person) }
  let(:subject_interface) { instance_double(Invoices::Abacus::SubjectInterface) }

  def person_jobs(p = person)
    Delayed::Job.where(handler: described_class.new(p).to_yaml)
  end

  def lock(delayed_job)
    delayed_job.update!(locked_at: Time.zone.now, locked_by: "worker-1")
    delayed_job
  end

  before { Delayed::Job.delete_all }

  describe "#enqueue!" do
    it "creates a job if none exists" do
      expect { job.enqueue! }.to change { person_jobs.count }.by(1)
    end

    it "does not create a second job if one is pending for the same person" do
      job.enqueue!
      expect { described_class.new(person).enqueue! }.not_to change { person_jobs.count }
    end

    it "creates a job if the existing job for the same person is already running" do
      lock(job.enqueue!)
      expect { described_class.new(person).enqueue! }.to change { person_jobs.count }.by(1)
    end

    it "creates a job if the pending job belongs to another person" do
      described_class.new(other_person).enqueue!
      expect { job.enqueue! }.to change { person_jobs.count }.by(1)
        .and not_change { person_jobs(other_person).count }
    end
  end

  describe "#before" do
    it "keeps the job running if it is the only one" do
      delayed_job = job.enqueue!
      expect { job.before(lock(delayed_job)) }.not_to change { person_jobs.count }
      expect(job.send(:person)).to eq(person)
    end

    it "keeps the job running if the other job is only pending" do
      delayed_job = job.enqueue!
      described_class.new(person).enqueue!(run_at: 1.hour.from_now)
      expect { job.before(lock(delayed_job)) }.not_to change { person_jobs.count }
      expect(job.send(:person)).to eq(person)
    end

    it "keeps the job running if the other running job belongs to another person" do
      delayed_job = job.enqueue!
      lock(described_class.new(other_person).enqueue!)
      expect { job.before(lock(delayed_job)) }.not_to change { person_jobs.count }
      expect(job.send(:person)).to eq(person)
    end

    it "reschedules the job if another job for the same person is running" do
      lock(described_class.new(person).enqueue!)
      delayed_job = lock(job.enqueue!)

      expect { job.before(delayed_job) }.to change { person_jobs.count }.by(1)
      expect(person_jobs.where(locked_at: nil).first.run_at).to be > Time.zone.now
      expect(job.send(:person)).to be_nil
    end

    it "does not reschedule twice if another job is already pending" do
      lock(described_class.new(person).enqueue!)
      described_class.new(person).enqueue!(run_at: 1.hour.from_now)
      delayed_job = lock(Delayed::Job.enqueue(job))

      expect { job.before(delayed_job) }.not_to change { person_jobs.count }
      expect(job.send(:person)).to be_nil
    end
  end

  describe "#perform" do
    before { allow(Invoices::Abacus::SubjectInterface).to receive(:new).and_return(subject_interface) }

    it "transmits the person" do
      expect(subject_interface).to receive(:transmit) do |subject|
        expect(subject.entity).to eq(person)
        true
      end
      job.perform
    end

    it "does not transmit if the job was rescheduled by #before" do
      lock(described_class.new(person).enqueue!)
      job.before(lock(job.enqueue!))

      expect(subject_interface).not_to receive(:transmit)
      job.perform
    end

    it "does not transmit if the person was deleted" do
      person.destroy!
      expect(subject_interface).not_to receive(:transmit)
      expect { job.perform }.not_to change { HitobitoLogEntry.count }
    end

    it "logs an error if the transmission fails" do
      expect(subject_interface).to receive(:transmit).and_return(false)
      expect { job.perform }.to change { HitobitoLogEntry.where(level: :error).count }.by(1)
    end
  end
end
