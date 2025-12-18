# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  class CleanupPeopleEmailBasedOnBounceResultsJob < BaseJob
    FILE = Rails.root.join("tmp", "bounce_results.csv")

    def perform
      PaperTrail.request.whodunnit = "CleanupPeopleEmailBasedOnBounceResultsJob"
      PaperTrail.request.controller_info = {mutation_id: ::SecureRandom.uuid,
                                            whodunnit_type: "script"}

      changed_people_ids = update_people_records

      abacus_sync(Person.where(id: changed_people_ids))
    end

    private

    def update_people_records
      total = csv_data.size
      processed = 0

      info "Updating people hitobito records"

      Person.transaction do
        csv_data.map do |row|
          person = Person.find_by(email: row["E-Mail"])

          person.correspondence = :print

          if row["Bounce-Typ"] == "hard"
            person.email = nil
            person.confirmed_at = nil
          end

          if !person.changed?
            info "Person has not changed: #{person.id}: #{row["E-Mail"]}"
            next
          end

          info "Hitobito update: #{person.id}: #{row["E-Mail"]}"

          person.save!(validate: false)

          processed += 1
          info "#{(processed / total.to_f * 100).to_i} % \r"
          person.id
        end
      end
    end

    def abacus_sync(scope)
      processed = 0
      total = scope.count
      scope.in_batches(of: 25) do |people|
        process_batch(people)
        processed += people.count
        info "#{(processed / total.to_f * 100).to_i} % \r"
      end
    end

    def process_batch(people)
      abacus_client.batch do
        people.map do |person|
          info "abacus sync: #{person.abacus_subject_key}"
          subject = Invoices::Abacus::Subject.new(person)
          abacus_client.batch_context_object = subject
          abacus_client.update(:customer, subject.subject_id, subject.customer_attrs)
        end
      end
    end

    def csv_data
      @csv_data ||= CSV.read(FILE, col_sep: ",", headers: true)
    end

    def abacus_client
      @abacus_client ||= Invoices::Abacus::Client.new
    end

    def info(msg)
      Rails.logger.info([self.class.to_s.demodulize, msg].join(": "))
    end
  end
end
