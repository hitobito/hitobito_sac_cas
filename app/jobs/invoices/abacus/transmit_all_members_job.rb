# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas
#
class Invoices::Abacus::TransmitAllMembersJob < BaseJob
  BATCH_SIZE = 1000 # number of people loaded per query
  SLICE_SIZE = 25  # number of people/invoices transmitted per abacus batch request
  PARALLEL_THREADS = 2 # number of threads sending abacus requests

  RELEVANT_ATTRIBUTES = Invoices::Abacus::Subject::RELEVANT_ATTRIBUTES + %w[id abacus_subject_key].freeze

  ROLES_TO_TRANSMIT = [
    Group::SektionsMitglieder::Mitglied,
    Group::SektionsNeuanmeldungenNv::Neuanmeldung,
    *SacCas::ABONNENT_MAGAZIN_ROLES
  ].freeze

  self.max_run_time = 12.hours

  include GracefulTermination

  def enqueue
    assert_no_other_job_running!
  end

  def perform
    handle_termination_signals do
      process_members
    end
  end

  def error(_job, exception, payload = parameters)
    HitobitoLogEntry.create!(
      level: :error,
      category: "rechnungen",
      message: exception.message,
      subject: nil,
      payload: payload
    )
    super
  end

  def failure(job)
    create_failure_log_entry(job.last_error)
  end

  def member_ids
    Person.joins(:roles)
      .where(roles: {type: ROLES_TO_TRANSMIT.map(&:sti_name)})
      .where.not(data_quality: :error)
      .distinct
      .order(:id)
      .select(:id)
  end

  private

  def process_members
    raise_exception = nil
    member_ids.in_batches(of: BATCH_SIZE) do |people|
      people_ids = people.pluck(:id)
      slices = people_ids.each_slice(SLICE_SIZE).to_a
      check_terminated!
      Parallel.map(slices, in_threads: PARALLEL_THREADS) do |slice|
        check_terminated!
        ActiveRecord::Base.connection_pool.with_connection do
          transmit_slice(slice)
        end
      rescue Exception => e # rubocop:disable Lint/RescueException we want to catch and re-raise all exceptions
        raise_exception = e
        raise Parallel::Break
      end

      raise raise_exception if raise_exception
    end
  end

  def transmit_slice(slice)
    people = Person.where(id: slice).select(*RELEVANT_ATTRIBUTES)
    subjects = people.map { |person| Invoices::Abacus::Subject.new(person) }
    parts = subject_interface.transmit_batch(subjects)
    log_error_parts(parts)
  end

  def subject_interface
    @subject_interface ||= Invoices::Abacus::SubjectInterface.new
  end

  def log_error_parts(parts)
    parts.reject(&:success?).each do |part|
      log_person_error(part)
    end
  end

  def log_person_error(part)
    HitobitoLogEntry.create!(
      subject: part.context_object.entity,
      category: "rechnungen",
      level: :error,
      message: "Die Personendaten konnten nicht an Abacus übermittelt werden",
      payload: part.error_payload
    )
  end

  def create_failure_log_entry(error)
    HitobitoLogEntry.create!(
      subject: nil,
      category: "rechnungen",
      level: :error,
      message: "Übermittlung Personendaten abgebrochen",
      payload: {error: error&.message, backtrace: error&.backtrace&.first(10)}
    )
  end

  def assert_no_other_job_running!
    raise "There is already a job running" if other_job_running?
  end

  def other_job_running?
    Delayed::Job.where("handler LIKE ?", "%#{self.class.name}%")
      .where(failed_at: nil).exists?
  end
end
