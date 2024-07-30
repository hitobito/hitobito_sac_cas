# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class PersonEntry
    attr_reader :row

    GENDERS = {
      "Männlich" => "m",
      "Weiblich" => "w"
    }.freeze

    LANGUAGES = {
      "DES" => "de",
      "FRS" => "fr",
      "ITS" => "it"
    }.freeze

    TARGET_ROLE = Group::ExterneKontakte::Kontakt.sti_name

    def initialize(row, group:, emails: [])
      @row = row
      @group = group
      @emails = emails
    end

    def person
      @person ||= ::Person.find_or_initialize_by(id: navision_id).tap do |person|
        assign_attributes(person)
        build_phone_numbers(person)
        build_role(person)
      end
    end

    def email
      @email ||= row.fetch(:email) if @emails.exclude?(row.fetch(:email))
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

    def to_s
      "#{person.to_s(:list)} (#{navision_id})"
    end

    private

    def assign_attributes(person) # rubocop:disable Metrics/AbcSize
      person.primary_group = @group
      person.first_name = row.fetch(:first_name)
      person.last_name = row.fetch(:last_name)
      person.zip_code = row.fetch(:zip_code)
      person.country = row.fetch(:country)
      person.town = row.fetch(:town)
      person.address_care_of = row.fetch(:address_supplement)
      person.street, person.housenumber = parse_address
      person.postbox = row.fetch(:postfach)

      if email.present?
        person.email = email
        # Do not call person#confirm here as it persists the record.
        # Instead we set confirmed_at manually.
        person.confirmed_at = Time.zone.at(0)
      end

      person.birthday = parse_datetime(row.fetch(:birthday))
      person.gender = GENDERS[row.fetch(:gender).to_s]
      person.language = LANGUAGES[row.fetch(:language)] || "de"
    end

    def build_phone_numbers(person)
      phone = row.fetch(:phone)
      mobile = row.fetch(:phone_mobile)
      direct = row.fetch(:phone_direct)

      # reset phone numbers first since import might be run multiple times
      person.phone_numbers = []

      person.phone_numbers.build(number: phone, label: "Privat") if phone_valid?(phone)
      person.phone_numbers.build(number: mobile, label: "Mobil") if phone_valid?(mobile)
      person.phone_numbers.build(number: direct, label: "Direkt") if phone_valid?(direct)
    end

    def build_role(person)
      return if person.roles.exists?

      person.roles.build(
        group: @group,
        type: TARGET_ROLE
      )
    end

    def parse_address
      address = row.fetch(:address)
      return if address.blank?

      Address::Parser.new(address).parse
    end

    def phone_valid?(number)
      number.present? && Phonelib.valid?(number)
    end

    def parse_datetime(value, default: nil)
      DateTime.parse(value.to_s)
    rescue Date::Error
      default
    end

    def navision_id
      Integer(row.fetch(:navision_id).to_s.sub!(/^0*/, ""))
    end

    def build_error_messages
      [person.errors.full_messages, person.roles.first.errors.full_messages]
        .flatten.compact.join(", ").tap do |messages|
        messages.prepend("#{self}: ") if messages.present?
      end
    end
  end
end
