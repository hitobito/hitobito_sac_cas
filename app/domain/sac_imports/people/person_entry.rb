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

    attr_reader :row, :groups, :warning, :existing_emails

    def initialize(row, groups, existing_emails)
      @row = row
      @groups = groups
      @warning = nil
      @existing_emails = existing_emails
    end

    def person
      @person ||= ::Person.includes(:additional_emails, :notes)
        .find_or_initialize_by(id: navision_id)
        .tap do |person|
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
      @navision_id ||= Integer(row.navision_id.to_s.sub(/^0*/, ""))
    end

    def country
      row.country || DEFAULT_COUNTRY
    end

    def gender
      GENDERS[row.gender&.to_sym]
    end

    def person_type
      PERSON_TYPES[row.person_type&.to_sym] || "person"
    end

    def language
      LANGUAGES[row.language&.to_sym] || DEFAULT_LANGUAGE
    end

    def email
      row.email&.downcase
    end

    def company?
      @is_company ||= person_type == "company"
    end

    def parse_address
      address = row.street_name
      return if address.blank?

      Address::Parser.new(address).parse
    end

    def assign_attributes(person) # rubocop:disable Metrics/AbcSize
      person.primary_group = group
      person.first_name = row.first_name unless company?
      person.last_name = row.last_name unless company?
      person.address_care_of = row.address_care_of
      person.postbox = row.postbox
      person.country = country
      person.town = row.town
      person.zip_code = row.zip_code
      person.birthday = row.birthday
      person.gender = gender unless company?
      person.language = language
      person.sac_remark_section_1 = row.sac_remark_section_1
      person.sac_remark_section_2 = row.sac_remark_section_2
      person.sac_remark_section_3 = row.sac_remark_section_3
      person.sac_remark_section_4 = row.sac_remark_section_4
      person.sac_remark_section_5 = row.sac_remark_section_5
      person.sac_remark_national_office = row.sac_remark_national_office
      if company?
        person.company = true
        person.company_name = [row.first_name.presence, row.last_name.presence].compact.join(" ")
      end

      if row.housenumber.present?
        person.street = row.street_name
        person.housenumber = row.housenumber
      else
        person.street, person.housenumber = parse_address
      end

      assign_email(person) if email.present?
    end

    def assign_email(person)
      if person.persisted?
        # for persisted people we have to do nothing if any of their email matches the new one
        person_emails = [person.email, *person.additional_emails.map(&:email)]
          .compact.map(&:downcase)
        return if person_emails.include?(email.downcase)
      end

      if existing_emails.add?(email.downcase)
        person.email = email
        # Do not call person#confirm here as it persists the record.
        # Instead we set confirmed_at manually.
        person.confirmed_at = Time.zone.at(0)
      else
        person.additional_emails = [::AdditionalEmail.new(email: email, label: "Duplikat")]
        warn(
          "Email #{email} already exists in the system. Importing with additional_email."
        )
      end
    end

    def phone_valid?(number)
      number.present? && Phonelib.valid?(number)
    end

    def build_phone_numbers(person)
      person.phone_numbers = [:phone, :phone_private, :phone_mobile, :phone_work].map do |attr|
        build_phone_number(person, attr)
      end.compact
    end

    def build_phone_number(person, attr)
      number = row.public_send(attr).presence || return
      label = phone_number_label(attr)

      return PhoneNumber.new(number:, label:) if phone_valid?(number)

      add_invalid_phone_number_as_note(person, number, label)
      nil
    end

    def phone_number_label(attr)
      case attr
      when :phone then "Haupt-Telefon"
      when :phone_private then "Privat"
      when :phone_mobile then "Mobil"
      when :phone_work then "Arbeit"
      end
    end

    def add_invalid_phone_number_as_note(person, number, label)
      return if person.notes.any? { |note| note.text.include?(number) }

      person.notes.build(
        author: Person.root,
        text: "Importiert mit ungültiger Telefonnummer (#{label}): #{number.inspect}"
      )
    end

    def build_role(person)
      person.roles.find_or_initialize_by(group: group, type: TARGET_ROLE)
    end

    def group
      case row.termination_reason
      when /Gestorben/i then groups.alumni
      else groups.import
      end
    end

    def build_error_messages
      [person.errors.full_messages, person.roles.first.errors.full_messages].flatten.compact.join(", ")
    end

    def warn(message)
      @warning = [@warning, message].compact.join(" / ")
    end
  end
end
