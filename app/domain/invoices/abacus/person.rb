# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class Person < Entity

      SALUTATION_IDS = {
        mister: 1,
        miss: 2,
        misses_and_misters: 3,
        family: 4,
        misters: 5,
        misses: 6
      }.freeze

      COMMUNICATION_TYPES = {
        email: 'EMail',
        phone: 'Phone',
        phone2: 'Phone2',
        fax: 'Fax',
        mobile: 'Mobile',
        www: 'WWW'
      }.freeze

      COMMUNICATION_CATEGORY_PRIVATE = 'Private'

      def transmit
        return false unless valid?

        entity.abacus_subject_key.present? ? update : create
        true
      end

      def create
        create_subject
        create_address
        create_communications
        create_customer
      end

      def update
        subject = fetch_subject
        update_subject(subject)
        update_address(subject[:addresses])
        update_communications(subject[:communications])
        update_customer(subject[:customers])
      end

      def fetch_subject
        client.get(:subject, subject_id, '$expand' => 'Addresses,Communications,Customers')
      end

      def validate
        @errors[:town] = :blank if entity.town.blank?
        @errors[:zip_code] = :blank if entity.zip_code.blank?
      end

      private

      def create_subject
        data = client.create(:subject, subject_attrs)
        entity.update_column(:abacus_subject_key, data[:id]) # rubocop:disable Rails/SkipsModelValidations
      end

      def update_subject(subject)
        attrs = subject_attrs
        if subject.slice(*attrs.keys) != attrs
          client.update(:subject, subject_id, attrs)
        end
      end

      def create_address
        client.create(:address, address_attrs)
      end

      def update_address(addresses)
        attrs = address_attrs
        attrs_values = attrs.except(:valid_from)
        current = addresses.max_by { |a| a[:valid_from] || Time.zone.today } || {}
        if current.slice(*attrs_values.keys) != attrs_values
          # Address updates are represented by creating a new address with a valid from date.
          client.create(:address, attrs)
        end
      end

      def create_communications
        communication_attrs.each do |attrs|
          client.create(:communication, attrs)
        end
      end

      def update_communications(communications)
        communication_attrs.each do |attrs|
          comm = communications.find { |c| c.fetch(:type) == attrs.fetch(:type) }
          if comm
            client.update(:communication, comm[:id], attrs) if comm[:value] != attrs.fetch(:value)
          else
            client.create(:communication, attrs)
          end
        end
      end

      def create_customer
        client.create(:customer, customer_attrs)
      end

      def update_customer(customers)
        return if customers.present?

        create_customer
      end

      def subject_id
        entity.abacus_subject_key.to_i
      end

      def subject_attrs
        # limit strings according to Abacus field lengths
        {
          name: entity.last_name.to_s[0, 100],
          first_name: entity.first_name.to_s[0, 50],
          language: entity.language,
          salutation_id: SALUTATION_IDS.fetch(entity.gender == 'm' ? :mister : :miss)
        }
      end

      def address_attrs # rubocop:disable Metrics/AbcSize
        # limit strings according to Abacus field lengths
        {
          subject_id: subject_id,
          street: entity.street.to_s[0, 50],
          house_number: entity.housenumber.to_s[0, 9],
          post_code: entity.zip_code[0, 15],
          city: entity.town.to_s[0, 50],
          country_id: entity.country || Countries.default.upcase,
          valid_from: Time.zone.today
        }
      end

      def communication_attrs
        [primary_email_attrs].compact
      end

      def primary_email_attrs
        return if entity.email.blank?

        # limit strings according to Abacus field lengths
        {
          subject_id: subject_id,
          type: COMMUNICATION_TYPES.fetch(:email),
          value: entity.email.to_s[0, 65],
          category: COMMUNICATION_CATEGORY_PRIVATE
        }
      end

      def customer_attrs
        {
          subject_id: subject_id
        }
      end

    end
  end
end
