# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class SubjectInterface
      def initialize(client = nil)
        @client = client
      end

      def transmit(subject)
        return false unless subject.valid?

        # Create abacus subject with id from hitobito.
        # If the id is already taken in abacus, flag an error
        remote = fetch(subject.subject_or_entity_id)
        return false if check_subject_key_taken(subject, remote)

        remote ? update(subject, remote) : create(subject)
        true
      end

      def transmit_batch(subjects)
        subjects.select!(&:valid?)

        # Initial people imports to hitobito are run multiple times, but People always get the same Id.
        # Each time, the database is cleared. Subjects persisted in Abacus, however, are not affected.
        # Because we use the same Id in hitobito and in Abacus, we fetch by Person#id from Abacus
        # if the abacus_subject_key is not set yet. If this Id already exists in Abacus, we assume it's
        # the same person and set the abacus_subject_key accordingly.
        parts = fetch_batch(subjects)
        batch_assign_abacus_subject_keys(parts)
        remotes = parts.map { |part| part.success? ? part.json : nil }
        existing, missing = subjects.zip(remotes).partition(&:last)
        create_batch(missing.map(&:first)) +
          update_batch(existing)
      end

      def fetch(subject_id)
        return if subject_id.zero?

        client.get(:subject, subject_id, "$expand" => "Addresses,Communications,Customers")
      rescue RestClient::NotFound
        nil
      end

      private

      def fetch_batch(subjects)
        client.batch do
          subjects.each do |subject|
            client.batch_context_object = subject
            fetch(subject.subject_or_entity_id)
          end
        end
      end

      def create(subject)
        data = create_subject_request(subject)
        subject.assign_subject_key(data)
        create_address(subject)
        create_communications(subject)
        create_customer(subject)
      end

      def create_batch(subjects)
        return [] if subjects.blank?

        subject_parts = create_batch_subjects(subjects)
        batch_assign_abacus_subject_keys(subject_parts)
        assoc_parts = create_batch_subject_associations(subjects)
        subject_parts + assoc_parts
      end

      def update(subject, remote)
        update_subject(subject, remote)
        update_address(subject, remote[:addresses])
        update_communications(subject, remote[:communications])
        delete_missing_communications(subject, remote[:communications])
        update_customer(subject, remote[:customers])
      end

      def update_batch(subjects_with_remotes)
        client.batch do
          subjects_with_remotes.each do |subject, remote|
            client.batch_context_object = subject
            update(subject, remote)
          end
        end
      end

      def create_subject_request(subject)
        client.create(:subject, subject.subject_attrs.merge(id: subject.entity.id))
      end

      def create_batch_subjects(subjects)
        client.batch do
          subjects.each do |subject|
            client.batch_context_object = subject
            create_subject_request(subject)
          end
        end
      end

      def batch_assign_abacus_subject_keys(parts)
        parts.each do |part|
          part.context_object.assign_subject_key(part.json) if part.success?
        end
      end

      def create_batch_subject_associations(subjects)
        client.batch do
          subjects.each do |subject|
            next if subject.subject_id.zero?

            client.batch_context_object = subject
            create_address(subject)
            create_communications(subject)
            create_customer(subject)
          end
        end
      end

      def update_subject(subject, remote)
        attrs = subject.subject_attrs
        if remote.slice(*attrs.keys) != attrs
          client.update(:subject, subject.subject_id, attrs)
        end
      end

      def create_address(subject)
        client.create(:address, subject.address_attrs)
      end

      def update_address(subject, addresses)
        attrs = subject.address_attrs
        attrs_values = attrs.except(:valid_from)
        current = addresses.max_by { |a| a[:valid_from] || Time.zone.today } || {}
        if current.slice(*attrs_values.keys) != attrs_values
          # Address updates are represented by creating a new address with a valid from date.
          client.create(:address, attrs)
        end
      end

      def create_communications(subject)
        subject.communication_attrs.each do |attrs|
          client.create(:communication, attrs)
        end
      end

      def update_communications(subject, communications)
        subject.communication_attrs.each do |attrs|
          comm = communications.find { |c| c.fetch(:type) == attrs.fetch(:type) }
          if comm
            client.update(:communication, comm[:id], attrs) if comm[:value] != attrs.fetch(:value)
          else
            client.create(:communication, attrs)
          end
        end
      end

      def delete_missing_communications(subject, communications)
        types = subject.communication_attrs.pluck(:type).uniq
        communications
          .reject { |c| types.include?(c.fetch(:type)) }
          .each { |c| client.delete(:communication, c.fetch(:id)) }
      end

      def create_customer(subject)
        client.create(:customer, subject.customer_attrs)
      end

      def update_customer(subject, customers)
        return if customers.present?

        create_customer(subject)
      end

      def check_subject_key_taken(subject, remote)
        if remote && subject.subject_id.zero?
          if same_person?(subject, remote)
            subject.assign_subject_key(remote)
            false
          else
            subject.errors[:abacus_subject_key] = :taken
            true
          end
        else
          false
        end
      end

      def same_person?(subject, remote)
        same_name?(subject, remote) && same_email?(subject, remote)
      end

      def same_name?(subject, remote)
        person_attrs = subject.person_subject_attrs.slice(:name, :first_name)
        remote.slice(*person_attrs.keys) == person_attrs
      end

      def same_email?(subject, remote)
        email_attrs = subject.primary_email_attrs
        return true if email_attrs.blank? && remote[:communications].blank?

        remote[:communications].any? do |c|
          c.fetch(:type) == email_attrs.fetch(:type) &&
            c.fetch(:value) == email_attrs.fetch(:value)
        end
      end

      def client
        @client ||= Client.new
      end
    end
  end
end
