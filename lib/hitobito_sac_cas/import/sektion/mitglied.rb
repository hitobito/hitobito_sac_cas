# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Import
  module Sektion
    class Mitglied
      attr_reader :row

      GENDERS = {
        'Männlich' => 'm',
        'Weiblich' => 'w'
      }.freeze

      LANGUAGES = {
        'DES' => 'de',
        'FRS' => 'fr',
        'ITS' => 'it'
      }.freeze

      BEITRAGSKATEGORIEN = {
        'EINZEL' => :einzel,
        'JUGEND' => :jugend,
        'FAMILIE' => :familie,
        'FREI KIND' => :familie,
        'FREI FAM' => :familie
      }.freeze

      TARGET_ROLE = Group::SektionsMitglieder::Mitglied.sti_name

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

      def valid?
        @valid ||= person.valid?
      end

      def errors
        @errors ||= valid? ? [] : build_error_messages
      end

      def to_s
        "#{navision_id} #{person}"
      end

      private

      def assign_attributes(person) # rubocop:disable Metrics/AbcSize
        person.first_name = row[:first_name]
        person.last_name = row[:last_name]
        person.zip_code = row[:zip_code]
        person.country = row[:country]
        person.town = row[:town]
        person.address = build_address

        if email.present?
          person.email = email
          person.confirm
        end

        person.birthday = parse_datetime(row[:birthday])
        person.gender = GENDERS[row[:gender].to_s]
        person.language = LANGUAGES[row[:language].to_s]
      end

      def build_phone_numbers(person)
        phone = row[:phone]
        phone_mobile = row[:phone_mobile]
        phone_direct = row[:phone_direct]
        return unless [phone, phone_mobile, phone_direct].any? { |n| phone_valid?(n) }
        # TODO: label translated based on language?
        person.phone_numbers.build(number: phone, label: 'Privat') if phone.present?
        person.phone_numbers.build(number: phone_mobile, label: 'Mobil') if phone_mobile.present?
        person.phone_numbers.build(number: phone_direct, label: 'Direkt') if phone_direct.present?
      end

      def build_role(person)
        created_at = parse_datetime(row[:role_created_at])
        deleted_at = parse_datetime(row[:role_deleted_at]) if quitted?
        category = BEITRAGSKATEGORIEN[row[:beitragskategorie]]

        person.roles.build(
          group: @group,
          type: Group::SektionsMitglieder::Mitglied,
          beitragskategorie: category,
          created_at: created_at,
          deleted_at: deleted_at
        )
      end

      def build_address
        [
          row[:address_supplement],
          row[:address],
          row[:postfach]
        ].select(&:present?).join("\n")
      end

      def phone_valid?(number)
        (number.present? && Phonelib.valid?(number))
      end

      def email
        @email ||= row[:email] if @emails.exclude?(row[:email])
      end

      def parse_datetime(value)
        DateTime.parse(value.to_s)
      rescue Date::Error
        nil
      end

      def beitragskategorie
        BEITRAGSKATEGORIEN[row[:beitragskategorie].to_s]
      end

      def navision_id
        Integer(row[:navision_id].to_s.sub!(/^0*/, ''))
      end

      def quitted?
        row[:member_type] == 'Ausgetreten'
      end

      def build_error_messages
        [person.errors.full_messages, person.roles.first.errors.full_messages]
          .flatten.join(', ').tap do |messages|
            messages.prepend("#{person}(#{person.id}): ") if messages.present?
          end
      end
    end
  end
end
