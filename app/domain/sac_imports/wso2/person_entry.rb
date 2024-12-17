# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Wso2
  class PersonEntry
    # Assume no gender if FIRMA is given
    GENDERS = {HERR: "m", FRAU: "w", FIRMA: nil}.freeze
    LANGUAGES = {D: "de", F: "fr", I: "it", E: "en"}.freeze
    DEFAULT_LANGUAGE = "de"
    DEFAULT_COUNTRY = "CH"

    include ActiveModel::Validations

    validate :valid_gender
    validate :at_least_one_role
    validate :person_must_exist_if_navision_id_is_present

    def at_least_one_role
      if !person.persisted? && person.roles.empty?
        errors.add(:roles, "can't be empty")
      end
    end

    def valid_gender
      return if row.gender.blank?
      if !GENDERS.include?(row.gender.to_sym)
        errors.add(:gender, "#{row.gender} is not a valid gender")
      end
    end

    def person_must_exist_if_navision_id_is_present
      if navision_id.present? && !person.persisted?
        errors.add(:base, "navision_id present put person not found")
      end
    end

    attr_reader :row
    attr_reader :warning

    def initialize(row, basic_login_group, tourenportal_group, existing_emails)
      @row = row
      @basic_login_group = basic_login_group
      @tourenportal_group = tourenportal_group
      @warning = nil
      @existing_emails = existing_emails
      person.new_record? ? assign_new_person_attributes : assign_existing_person_attributes
      assign_roles
    end

    def person
      @person ||= find_person || Person.new
    end

    def valid?
      super
      person.valid?(context: :import)

      errors.merge!(person.errors)
      person.roles.each do |role|
        errors.merge!(role.errors)
      end

      errors.empty?
    end

    def error_messages
      (errors.full_messages + [warning]).join(", ")
    end

    def um_id_tag ="UM-ID-#{row.um_id}"

    def gender
      GENDERS[row.gender&.to_sym]
    end

    def import!
      raise ActiveRecord::RecordInvalid unless valid?

      person.save!(context: :import)
    end

    private

    def assign_common_attributes
      person.wso2_legacy_password_hash = row.wso2_legacy_password_hash
      person.wso2_legacy_password_salt = row.wso2_legacy_password_salt

      if row.email_verified == "1"
        person.confirmed_at ||= Time.zone.at(0)
        person.correspondence = "digital"
      else
        person.correspondence = "print" unless person.confirmed_at?
      end
      person.um_id = um_id_tag
    end

    def assign_existing_person_attributes
      assign_common_attributes
      assign_email_existing_person
    end

    def assign_new_person_attributes
      assign_common_attributes
      assign_email_new_person

      person.first_name = row.first_name
      person.last_name = row.last_name
      person.address_care_of = row.address_care_of
      person.postbox = row.postbox
      person.address = row.address

      person.street, person.housenumber = row.address && Address::Parser.new(row.address).parse

      person.country = country
      person.town = row.town
      person.zip_code = row.zip_code&.strip
      person.birthday = row.birthday
      person.gender = gender
      person.language = language
      build_phone_number(person, :phone, "Haupt-Telefon")
      build_phone_number(person, :phone_business, "Arbeit")
    end

    def build_phone_number(person, attr, label)
      number_string = row.public_send(attr).presence || return
      number = Phonelib.parse(number_string)

      if number.valid?
        formatted_number = number.international # as formatted in callback on PhoneNumber
        return if person.phone_numbers.any? { |phone| phone.number == formatted_number }

        person.phone_numbers.build(number: formatted_number, label: label)
      else
        add_invalid_phone_number_as_note(person, number_string, label)
      end
    end

    def add_invalid_phone_number_as_note(person, number_string, label)
      return if person.notes.any? { |note| note.text.include?(number_string) }

      person.notes.build(
        author: Person.root,
        text: "Importiert mit ungültiger Telefonnummer #{label}: '#{number_string}'"
      )
    end

    def phone_valid?(number) = number.present? && Phonelib.valid?(number)

    def assign_email_existing_person
      return if email.blank? || person.email&.downcase == email # emails match, nothing to do

      if @existing_emails.add?(email)
        if person.email.present?
          warn("Email mismatch, overwriting current email #{person.email} with #{email}")
        end
        person.email = email # email from WSO2 takes precedence
      else
        warn("Email #{email} already exists in the system, importing with additional_email.")
        unless person.additional_emails.any? { |e| e.email == email }
          person.additional_emails.build(email:, label: "Duplikat")
        end
      end
    end

    def assign_email_new_person
      return if email.blank?

      # if email is not taken yet, assign it
      person.email = email and return if @existing_emails.add?(email.downcase)

      # otherwise do not assign an email but add it as additional email
      person.additional_emails.build(email:, label: "Duplikat")
      warn(
        "Email #{email} already exists in the system, importing with additional_email."
      )
    end

    def assign_roles
      if row.role_abonnent == "1"
        assign_role(person, @tourenportal_group, Group::AboTourenPortal::Abonnent.sti_name)
      end
      if row.role_gratisabonnent == "1"
        assign_role(person, @tourenportal_group, Group::AboTourenPortal::Gratisabonnent.sti_name)
      end

      # do not assign basic login role if person is already SAC member
      return if person.sac_membership_active?

      if row.role_basiskonto == "1"
        assign_role(person, @basic_login_group, Group::AboBasicLogin::BasicLogin.sti_name)
      end
    end

    def assign_role(person, group, type)
      person.roles.where(group:, type:).first_or_initialize
    end

    def language
      LANGUAGES[row.language&.to_sym] || DEFAULT_LANGUAGE
    end

    def country
      row.country || DEFAULT_COUNTRY
    end

    def email
      row.email&.downcase
    end

    def navision_id
      @navision_id ||= Integer(row.navision_id.to_s.sub(/^0*/, ""), exception: false)
    end

    def find_person
      person ||= Person.find_by(id: navision_id) if navision_id.present?
      person ||= Person.find_by(email: email) if email.present?
      person || Person.where(um_id: um_id).first
    end

    def warn(message)
      @warning = [@warning, message].compact.join(" / ")
    end
  end
end
