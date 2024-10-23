# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class Subject < Entity
      RELEVANT_ATTRIBUTES = %w[first_name last_name email language gender street
        housenumber zip_code town country].freeze

      SALUTATION_IDS = {
        mister: 1,
        miss: 2,
        misses_and_misters: 3,
        family: 4,
        misters: 5,
        misses: 6
      }.freeze

      COMMUNICATION_TYPES = {
        email: "EMail",
        phone: "Phone",
        phone2: "Phone2",
        fax: "Fax",
        mobile: "Mobile",
        www: "WWW"
      }.freeze

      COMMUNICATION_CATEGORY_PRIVATE = "Private"

      def validate
        @errors[:town] = :blank if entity.town.blank?
        @errors[:zip_code] = :blank if entity.zip_code.blank?
      end

      def subject_id
        entity.abacus_subject_key.to_i
      end

      def subject_or_entity_id
        (entity.abacus_subject_key || entity.id).to_i
      end

      def assign_subject_key(data)
        # Raise an error if abacus did not use the person.id as subject key
        # (even though SubjectInterface checked that the person.id is not taken yet in Abacus)
        raise "Abacus created subject with id=#{data[:id]} but person has id=#{entity.id}" if entity.id != data[:id].to_i

        entity.update_column(:abacus_subject_key, data[:id]) unless entity.abacus_subject_key == data[:id]  # rubocop:disable Rails/SkipsModelValidations
      end

      def subject_attrs
        # limit strings according to Abacus field lengths
        {
          name: entity.last_name.to_s[0, 100],
          first_name: entity.first_name.to_s[0, 50],
          language: entity.language,
          salutation_id: SALUTATION_IDS.fetch((entity.gender == "m") ? :mister : :miss)
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
