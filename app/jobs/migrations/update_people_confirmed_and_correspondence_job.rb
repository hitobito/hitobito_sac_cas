# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  class UpdatePeopleConfirmedAndCorrespondenceJob < BaseJob
    def perform
      with_before_and_after_correspondence_info do
        update_people_without_email
        update_unconfirmed_people
        update_confirmed_at_for_people_with_valid_email
        update_correspondence_to_digital_for_confirmed_people
        update_confirmed_at_for_people_with_invalid_email
      end
    end

    private

    def with_before_and_after_correspondence_info
      print_correspondence_info(Person, "all")
      print_correspondence_info(people_with_email, "with email")
      print_correspondence_info(invoice_receivers, "invoice receivers")
      yield
      print_correspondence_info(Person, "all")
      print_correspondence_info(people_with_email, "with email")
      print_correspondence_info(invoice_receivers, "invoice receivers")
    end

    def people_with_email = Person.where.not(email: nil)

    def invoice_receivers
      Person.joins(:roles)
        .where(roles: {type: SacCas::MITGLIED_ROLES.map(&:sti_name)})
        .where(
          "roles.beitragskategorie IN (?) OR people.sac_family_main_person = ?",
          %w[adult youth],
          true
        ).distinct
    end

    def print_correspondence_info(scope, message)
      info "#{message.ljust(18)}: #{scope.group(:correspondence).count}"
    end

    def update_people_without_email
      Person
        .where(email: nil, correspondence: :digital)
        .update_all(correspondence: :print, confirmed_at: nil)
    end

    def update_unconfirmed_people
      Person
        .where(unconfirmed_conditions).where(correspondence: :digital)
        .update_all(correspondence: :print)
    end

    def update_confirmed_at_for_people_with_valid_email
      updated = unconfirmed.in_batches.inject(0) do |count, people|
        valid = people.select { |person| Truemail.valid?(person.email, with: :regex) }
        Person.where(id: valid.map(&:id)).update_all(confirmed_at: migrated_at) + count
      end
      return unless updated.positive?
      info "Updated #{updated} unconfirmed, new unconfirmed count: #{unconfirmed.count}"
    end

    def update_confirmed_at_for_people_with_invalid_email
      Person.where(email: nil).where.not(confirmed_at: nil).update_all(confirmed_at: nil)
    end

    def update_correspondence_to_digital_for_confirmed_people
      people_ids = Person
        .where.not(email: nil)
        .where.not(unconfirmed_conditions)
        .where(correspondence: :print)
        .joins("LEFT OUTER JOIN versions ON " \
          "versions.item_type = 'Person' AND versions.item_id = people.id AND " \
          "versions.object_changes LIKE '%correspondence:\n%- digital\n- print\n%'")
        .where(versions: {id: nil})
        .pluck(:id)

      return if people_ids.empty?

      info "Updating #{people_ids.count} correspondences"
      Person.where(id: people_ids).update_all(correspondence: :digital)
      abacus_sync(Person.where(id: people_ids).where.not(abacus_subject_key: nil))
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

    def abacus_client
      @abacus_client ||= Invoices::Abacus::Client.new
    end

    def unconfirmed
      Person
        .where(unconfirmed_conditions)
        .where("email is not null and encrypted_password is not null")
    end

    def unconfirmed_conditions = {confirmed_at: [nil, Time.zone.at(0)]}

    def migrated_at = Time.zone.local(2024, 12, 21, 21)

    def info(msg)
      Rails.logger.info([self.class.to_s.demodulize, msg].join(": "))
    end
  end
end
