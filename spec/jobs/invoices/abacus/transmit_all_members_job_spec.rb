# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::Abacus::TransmitAllMembersJob do
  let(:job) { described_class.new }

  let(:expected_people) do
    # People that should show up
    people(:mitglied).update!(abacus_subject_key: "123")
    people(:familienmitglied).update!(abacus_subject_key: "124")
    valid_person = create_person(params: {abacus_subject_key: "128", first_name: "Joe", last_name: "Doe"})
    [
      people(:mitglied),
      people(:familienmitglied),
      people(:familienmitglied2),
      people(:familienmitglied_kind),
      valid_person,
      create_person(params: {abacus_subject_key: "129", first_name: "Jane", last_name: "Doe"}),
      create_person(params: {abacus_subject_key: "130", first_name: "Jeffery", last_name: "Doe"}),
      create_person(params: {abacus_subject_key: "131", first_name: "Jack", last_name: "Doe"})
    ]
  end

  let(:unexpected_people) do
    person_1 = Fabricate.create(:person_with_address)
    person_2 = Fabricate.create(:person_with_address)
    [
      person_1,
      person_2
    ]
  end

  def create_mix_of_people
    expected_people
    unexpected_people
  end

  describe "#process_members" do
    it "processes members in batches and slices" do
      expect(job).to receive(:transmit_slice).once
      allow(job).to receive(:transmit_slice).with(any_args).and_return(true)
      job.send(:process_members)
    end
  end

  describe "#enqueue!" do
    it "will create a job and raise if there is already one running" do
      expect { job.enqueue! }.to change(Delayed::Job, :count).by(1)
      expect { job.enqueue! }.to raise_error("There is already a job running")
    end
  end

  describe "#perform" do
    let(:subject_interface) { instance_double(Invoices::Abacus::SubjectInterface) }
    let(:subject) { instance_double(Invoices::Abacus::Subject) }

    let(:job_instance) do
      job.enqueue!
    end

    before do
      create_mix_of_people
      allow(Invoices::Abacus::SubjectInterface).to receive(:new).and_return(subject_interface)

      allow(subject_interface).to receive(:transmit_batch).with(any_args).and_invoke(->(subjects) {
        mock_parts(subjects)
      })

      stub_const("Invoices::Abacus::TransmitAllMembersJob::BATCH_SIZE", 4)
      stub_const("Invoices::Abacus::TransmitAllMembersJob::SLICE_SIZE", 2)
      stub_const("Invoices::Abacus::TransmitAllMembersJob::PARALLEL_THREADS", 2)
    end

    it "processes members in batches" do
      expect(job).to receive(:process_members)
      job.perform
    end

    it "transmits slice" do
      expect(subject_interface).to receive(:transmit_batch)
      expect(job).to receive(:log_error_parts)
      job.send(:transmit_slice, Person.all)
    end

    it "returns correct member ids" do
      expected_people
      expect(job.send(:member_ids).map(&:id)).to eq(expected_people.pluck(:id))
    end

    it "re-raises the error if an error occurs" do
      allow(subject_interface).to receive(:transmit_batch).and_raise(StandardError.new("Test error"))
      expect { job.send(:transmit_slice, slice) }.to raise_error(StandardError)
    end

    it "re-raises the error if there is an error in the second thread" do
      # Mock transmit_batch to succeed on first call and raise an exception on second call
      allow(subject_interface).to receive(:transmit_batch).with(any_args).and_invoke(->(subjects) {
        @call_count ||= 0
        @call_count += 1

        if @call_count == 1
          slice_size = Invoices::Abacus::TransmitAllMembersJob::SLICE_SIZE
          subjects = expected_people.first(slice_size).map { |person| Invoices::Abacus::Subject.new(person) }
          mock_parts(subjects)
        else
          raise StandardError, "Simulated error on second call"
        end
      })
      allow(Delayed::Worker).to receive(:max_attempts).and_return(2)
      expect { Delayed::Worker.new.run(job.enqueue!) }
        .to change { HitobitoLogEntry.where(level: :error).count }.by(1)

      # test that error is logged through error method
      expect(HitobitoLogEntry.where(level: :error).last.message).to eq("Simulated error on second call")
    end

    it "runs the job correctly if there is no error" do
      allow(subject_interface).to receive(:transmit_batch).with(any_args).and_invoke(->(subjects) {
        mock_parts(subjects)
      })
      expect { job.perform }.not_to raise_error
    end

    it "logs and error if parts there is an error in the second thread" do
      # Mock transmit_batch to succeed on first call and raise an exception on second call
      allow(subject_interface).to receive(:transmit_batch).with(any_args)
        .and_invoke(->(subjects) {
                      @call_count ||= 0
                      @call_count += 1

                      if @call_count == 1
                        slice_size = Invoices::Abacus::TransmitAllMembersJob::SLICE_SIZE
                        subjects = expected_people.first(slice_size).map { |person| Invoices::Abacus::Subject.new(person) }
                        mock_parts(subjects)
                      else
                        mock_parts(subjects, error_payload: "Simulated error on second call")
                      end
                    })
      allow(Delayed::Worker).to receive(:max_attempts).and_return(2)
      expect { Delayed::Worker.new.run(job.enqueue!) }
        .to change { HitobitoLogEntry.where(level: :error).count }.by(6)

      # test that error is logged through error method
      expect(HitobitoLogEntry.where(level: :error).last.message).to eq("Die Personendaten konnten nicht an Abacus übermittelt werden")
    end

    it "finishes all threads cleanly" do
      create_mix_of_people
      expected_people.map(&:id).sort.each_slice(2) do |slice|
        expect(job).to receive(:transmit_slice).with(slice)
      end
      job.perform
    end

    it "finishes correct number of threads in error case" do
      create_mix_of_people
      expect(subject_interface).to receive(:transmit_batch).and_return([mock_part(people(:mitglied)), mock_part(people(:familienmitglied), success: false)])
      expect(subject_interface).to receive(:transmit_batch).and_raise(StandardError, "Simulated error on second call")

      expect do
        expect { job.perform }.to raise_error(StandardError, "Simulated error on second call")
      end.to change { HitobitoLogEntry.count }.by(1)

      log = HitobitoLogEntry.find_by(subject: people(:familienmitglied), category: "rechnungen")
      expect(log).to be_present
    end
  end

  describe "#error" do
    let(:exception) { StandardError.new("Test error").tap { |e| e.set_backtrace(["foo", "bar"]) } }

    it "creates a log entry and calls super" do
      expect(HitobitoLogEntry).to receive(:create!).with(
        level: :error,
        category: "rechnungen",
        message: "Test error",
        subject: nil,
        payload: job.parameters
      )

      job.error(nil, exception)
    end
  end

  describe "#failure" do
    let(:job_double) { instance_double(Delayed::Job, last_error: "Test error") }

    it "creates a failure log entry" do
      expect(job).to receive(:create_failure_log_entry).with("Test error")
      job.failure(job_double)
    end
  end

  describe "#create_failure_log_entry" do
    let(:exception) { StandardError.new("Test error").tap { |e| e.set_backtrace(["foo", "bar"]) } }

    it "creates a log entry for job failure" do
      expect(HitobitoLogEntry).to receive(:create!).with(
        subject: nil,
        category: "rechnungen",
        level: :error,
        message: "Übermittlung Personendaten abgebrochen",
        payload: {error: "Test error", backtrace: exception.backtrace&.first(10)}
      )
      job.send(:create_failure_log_entry, exception)
    end
  end

  def mock_parts(subjects, error_payload: nil)
    subjects.map do |subject|
      mock_part(subject.entity, success: error_payload.nil?)
    end
  end

  def mock_part(person, success: true)
    double(
      "Part",
      success?: success,
      context_object: double("Subject", to_s: [person.first_name, person.last_name].join(" "), entity: person),
      error_payload: "error payload"
    )
  end

  def create_person(role_created_at: Date.new(2024, 1, 1), params: {})
    group = groups(:bluemlisalp_mitglieder)
    person = Fabricate.create(:person_with_address, **params)
    Fabricate.create(Group::SektionsMitglieder::Mitglied.sti_name, created_at: role_created_at, group:, person:)
    person
  end
end
