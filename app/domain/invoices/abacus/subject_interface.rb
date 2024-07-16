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

      # Requires abacus
      def transmit(subject)
        return false unless subject.valid?

        remote = fetch(subject.subject_id)
        remote ? update(subject, remote) : create(subject)
        true
      end

      def fetch(subject_id)
        return if subject_id.zero?

        client.get(:subject, subject_id, "$expand" => "Addresses,Communications,Customers")
      rescue RestClient::NotFound
        nil
      end

      def create(subject)
        data = create_subject_request(subject)
        subject.assign_subject_key(data)
        create_address(subject)
        create_communications(subject)
        create_customer(subject)
      end

      def create_batch(subjects)
        batch_response = create_batch_subjects(subjects)
        assign_abacus_subject_keys(subjects, batch_response)
        create_batch_subject_associations(subjects)
      end

      def update(subject, remote)
        update_subject(subject, remote)
        update_address(subject, remote[:addresses])
        update_communications(subject, remote[:communications])
        update_customer(subject, remote[:customers])
      end

      private

      def create_subject_request(subject)
        # create abacus subject with id from hitobito if possible
        client.create(:subject, subject.subject_attrs.merge(id: subject.entity.id))
      end

      def create_batch_subjects(subjects)
        client.batch do
          subjects.each do |subject|
            create_subject_request(subject)
          end
        end
      end

      def assign_abacus_subject_keys(subjects, batch_response)
        subjects.each_with_index do |subject, index|
          part = batch_response.parts[index]
          subject.assign_subject_key(part.json) if part&.created?
        end
      end

      def create_batch_subject_associations(subjects)
        client.batch do
          subjects.each do |subject|
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

      def create_customer(subject)
        client.create(:customer, subject.customer_attrs)
      end

      def update_customer(subject, customers)
        return if customers.present?

        create_customer(subject)
      end

      def client
        @client ||= Client.new
      end
    end
  end
end
