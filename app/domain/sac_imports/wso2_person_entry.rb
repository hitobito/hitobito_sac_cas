# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Wso2PersonEntry
    GENDERS = {HERR: "m", FRAU: "w"}.freeze
    LANGUAGES = {D: "de", F: "fr", I: "it", E: "en"}.freeze
    DEFAULT_LANGUAGE = "de"
    DEFAULT_COUNTRY = "CH"

    include ActiveModel::Validations

    validate :existing_and_wso2_email_matches
    validate :valid_gender
    validate :at_least_one_role
    validate :person_must_exist_if_navision_id_is_present

    def existing_and_wso2_email_matches
      if person.persisted? && email != person.email
        errors.add(:email, "#{row[:email]} does not match the current email")
      end
      if !person.persisted? && Person.exists?(email: email)
        errors.add(:email, "#{row[:email]} already exists")
      end
    end

    def at_least_one_role
      if !person.persisted? && person.roles.empty?
        errors.add(:roles, "can't be empty")
      end
    end

    def valid_gender
      return if row[:gender].blank?
      if !GENDERS.include?(row[:gender].to_sym)
        errors.add(:gender, "#{row[:gender]} is not a valid gender")
      end
    end

    def person_must_exist_if_navision_id_is_present
      if navision_id.present? && !person.persisted?
        errors.add(:base, "navision_id present put person not found")
      end
    end

    attr_reader :row

    def initialize(row, basic_login_group, abo_group)
      @row = row
      @basic_login_group = basic_login_group
      @abo_group = abo_group
    end

    def person
      @person ||= find_or_initialize_person(row).tap do |person|
        if person.persisted?
          assign_attributes_for_existing_person(person)
        else
          assign_attributes(person)
        end
        assign_roles(person)
      end
    end

    def valid?
      self_valid = super
      person_valid = person.valid?

      errors.merge!(person.errors)
      person.roles.each do |role|
        errors.merge!(role.errors)
      end

      self_valid && person_valid
    end

    def error_messages
      errors.full_messages.join(", ")
    end

    def import!
      raise ActiveRecord::RecordInvalid if !valid?
      person.save!
    end

    private

    def assign_common_attributes(person)
      person.wso2_legacy_password_hash = row[:wso2_legacy_password_hash]
      person.wso2_legacy_password_salt = row[:wso2_legacy_password_salt]
      if row[:email_verified] == "1"
        person.confirmed_at = Time.zone.at(0)
        person.correspondence = "digital"
      end
    end

    def assign_attributes_for_existing_person(person)
      assign_common_attributes(person)
    end

    def assign_attributes(person)
      assign_common_attributes(person)

      person.primary_group = @basic_login_group
      person.email = email

      person.first_name = row[:first_name]
      person.last_name = row[:last_name]
      person.address_care_of = row[:address_care_of]
      person.postbox = row[:postbox]
      person.address = row[:address]

      person.street, person.housenumber = row[:address] && Address::Parser.new(row[:address]).parse

      person.country = country
      person.town = row[:town]
      person.zip_code = row[:zip_code]
      person.birthday = row[:birthday]
      person.gender = gender
      person.language = language
      person.phone_numbers.build(
        number: row[:phone],
        label: "Mobil"
      )
      person.phone_numbers.build(
        number: row[:phone_business],
        label: "Arbeit"
      )
    end

    def assign_roles(person)
      return if person.sac_membership_active?

      if row[:role_basiskonto] == "1"
        assign_role(person, @basic_login_group, Group::AboBasicLogin::BasicLogin.sti_name)
      end
      if row[:role_abonnent] == "1"
        assign_role(person, @abo_group, Group::AboTourenPortal::Abonnent.sti_name)
      end
      if row[:role_gratisabonnent] == "1"
        assign_role(person, @abo_group, Group::AboTourenPortal::Gratisabonnent.sti_name)
      end
    end

    def assign_role(person, group, type)
      person.roles.where(group:, type:).first_or_initialize
    end

    def language
      LANGUAGES[row[:person_type]&.to_sym] || DEFAULT_LANGUAGE
    end

    def country
      row[:country] || DEFAULT_COUNTRY
    end

    def gender
      GENDERS[row[:gender]&.to_sym]
    end

    def email
      row[:email]&.downcase
    end

    def navision_id
      @navision_id ||= Integer(row[:navision_id].to_s.sub(/^0*/, ""), exception: false)
    end

    def find_or_initialize_person(row)
      existing_person = navision_id && Person.find_by_id(navision_id)
      return existing_person if existing_person.present?

      Person.where(primary_group: @basic_login_group, email: email).first_or_initialize
    end
  end
end
