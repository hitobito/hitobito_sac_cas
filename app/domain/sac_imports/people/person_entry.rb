# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::People
  class PersonEntry
    GENDERS = {"0": "m", "1": "w"}.freeze
    PERSON_TYPES = {"1": "person", "2": "company"}.freeze
    DEFAULT_LANGUAGE = "de"
    LANGUAGES = {DES: "de", FRS: "fr", ITS: "it"}.freeze
    DEFAULT_COUNTRY = "CH"
    TARGET_ROLE = Group::ExterneKontakte::Kontakt.sti_name

    attr_reader :row, :group, :warning

    def initialize(row, group)
      @row = row
      @group = group
      @warning = nil
    end

    def person
      @person ||= ::Person.find_or_initialize_by(id: navision_id).tap do |person|
        assign_attributes(person)
        build_phone_numbers(person)
        build_role(person)
      end
    end

    def valid?
      @valid ||= person.valid?
    end

    def errors
      @errors ||= valid? ? [] : build_error_messages
    end

    def import!
      person.save!
    end

    private

    def navision_id
      @navision_id ||= Integer(row[:navision_id].to_s.sub(/^0*/, ""))
    end

    def country
      row[:country] || DEFAULT_COUNTRY
    end

    def gender
      GENDERS[row[:gender]&.to_sym]
    end

    def person_type
      PERSON_TYPES[row[:person_type]&.to_sym] || "person"
    end

    def language
      LANGUAGES[row[:person_type]&.to_sym] || DEFAULT_LANGUAGE
    end

    def email
      row[:email]
    end

    def company?
      @is_company ||= person_type == "company"
    end

    def parse_address
      address = row[:street_name]
      return if address.blank?

      Address::Parser.new(address).parse
    end

    def assign_attributes(person) # rubocop:disable Metrics/AbcSize
      person.primary_group = group
      person.first_name = row[:first_name] unless company?
      person.last_name = row[:last_name] unless company?
      person.address_care_of = row[:address_care_of]
      person.postbox = row[:postbox]
      person.country = country
      person.town = row[:town]
      person.zip_code = row[:zip_code]
      person.birthday = row[:birthday]
      person.gender = gender unless company?
      person.language = language
      person.family_key = row[:family]
      person.sac_remark_section_1 = row[:sac_remark_section_1]
      person.sac_remark_section_2 = row[:sac_remark_section_2]
      person.sac_remark_section_3 = row[:sac_remark_section_3]
      person.sac_remark_section_4 = row[:sac_remark_section_4]
      person.sac_remark_section_5 = row[:sac_remark_section_5]
      person.sac_remark_national_office = row[:sac_remark_national_office]
      person.company = company?
      person.company_name = row[:last_name] if company?

      if row[:housenumber].present?
        person.street = row[:street_name]
        person.housenumber = row[:housenumber]
      else
        person.street, person.housenumber = parse_address
      end

      if email.present?
        if Person.where.not(id: person.id).where(email: email).exists?
          person.additional_emails << ::AdditionalEmail.new(email: email, label: "Duplikat")
          @warning = "Email #{email} already exists in the system. Importing with additional_email."
        else
          person.email = email
          # Do not call person#confirm here as it persists the record.
          # Instead we set confirmed_at manually.
          person.confirmed_at = Time.zone.at(0)
        end
      end
    end

    def phone_valid?(number)
      number.present? && Phonelib.valid?(number)
    end

    def build_phone_numbers(person)
      # rubocop:disable Lint/SymbolConversion
      phone_numbers = {
        "Hauptnummer": row[:phone]
      }.freeze
      # rubocop:enable Lint/SymbolConversion

      phone_numbers.each do |label, number|
        person.phone_numbers.find_or_initialize_by(number: number, label: label) if phone_valid?(number)
      end
    end

    def build_role(person)
      person.roles.find_or_initialize_by(group: group, type: TARGET_ROLE)
    end

    def build_error_messages
      [person.errors.full_messages, person.roles.first.errors.full_messages].flatten.compact.join(", ")
    end
  end
end
