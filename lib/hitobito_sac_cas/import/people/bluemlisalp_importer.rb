# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('lib', 'import', 'xlsx_reader.rb')

module Import
  module People
    class BluemlisalpImporter

      HEADERS = {
        navision_id: 'Mitgliedernummer',
        first_name: 'Vorname',
        last_name: 'Nachname',
        address_supplement: 'Adresszusatz',
        address: 'Adresse',
        country: 'Länder-/Regionscode',
        town: 'Ort',
        zip_code: 'PLZ',
        email: 'E-Mail',
        postfach: 'Postfach',
        phone: 'Telefon',
        phone_direct: 'Telefon direkt',
        phone_mobile: 'Mobiltelefon',
        birthday: 'Geburtsdatum',
        gender: 'Geschlecht',
        group_navision_id: 'Sektion',
        role_type: 'Kategorie',
        member_type: 'Mitgliederart',
        language: 'Sprachcode',
        role_created_at: 'Letztes Eintrittsdatum',
        role_deleted_at: 'Letztes Austrittsdatum',
      }

      GENDERS = {
        'Männlich' => 'm',
        'Weiblich' => 'w'
      }

      LANGUAGES = {
        'DES' => 'de',
        'FRS' => 'fr',
        'ITS' => 'it'
      }

      ROLE_TYPES = {
        'EINZEL' => 'Group::SektionsMitglieder::Einzel',
        'JUGEND' => 'Group::SektionsMitglieder::Jugend',
        'FAMILIE' => 'Group::SektionsMitglieder::Familie',
        'FREI KIND' => 'Group::SektionsMitglieder::FreiKind',
        'FREI FAM' => 'Group::SektionsMitglieder::FreiFam'
      }

      attr_reader :output

      def initialize(path, output: STDOUT)
        raise 'Personen Bluemlisalp Export excel file not found' unless path.exist?
        @path = path
        @output = output
      end

      def import!
        without_query_logging do
          Import::XlsxReader.read(@path, 'Data', headers: HEADERS) do |row|
            output.puts "Importing row #{row[:first_name]} #{row[:last_name]}"
            person = person_for(row)
            person = set_data(row, person)
            # TODO handle group not being found and thus no role
            begin
              person.save!
              output.puts "Finished importing #{person.full_name}"
            rescue ActiveRecord::RecordInvalid => e
              output.puts "CAN NOT IMPORT ROW WITH NAVISION ID: #{row[:navision_id]}\n#{e.message}"
            end
          end
        end
      end

      private

      def without_query_logging
        old_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = nil
        yield
        ActiveRecord::Base.logger = old_logger
      end

      def person_for(row)
        ::Person.find_or_initialize_by(id: navision_id(row))
      end

      def set_data(row, person)
        person.first_name = first_name(row)
        person.last_name = last_name(row)
        person.address = address(row)
        person.country = country(row)
        person.zip_code = zip_code(row)
        person.town = town(row)
        set_phone(row, person)
        person.email = email(row)
        person.birthday = birthday(row)
        person.gender = gender(row)
        person.language = language(row)
        set_role(row, person)
        person
      end

      def navision_id(row)
        Integer(row[:navision_id].to_s.sub!(/^[0]*/, ''))
      end

      def first_name(row)
        row[:first_name].to_s
      end

      def last_name(row)
        row[:last_name].to_s
      end

      def address(row)
        [
          row[:address_supplement],
          row[:address],
          row[:postfach],
        ].select(&:present?).join("\n")
      end

      def country(row)
        row[:country].to_s
      end

      def zip_code(row)
        row[:zip_code].to_s
      end

      def town(row)
        row[:town].to_s
      end

      def set_phone(row, person)
        phone = row[:phone]
        phone_mobile = row[:phone_mobile]
        phone_direct = row[:phone_direct]
        return unless [phone, phone_mobile, phone_direct].any? { |n| phone_valid?(n) }
        person.phone_numbers.destroy_all
        # TODO label translated based on language?
        person.phone_numbers.build(number: phone, label: 'Privat') if phone.present?
        person.phone_numbers.build(number: phone_mobile, label: 'Mobil') if phone_mobile.present?
        person.phone_numbers.build(number: phone_direct, label: 'Direkt') if phone_direct.present?
      end

      def phone_valid?(number)
        (number.present? && Phonelib.valid?(number))
      end

      def email(row)
        email = row[:email]
        return unless email.present? && Truemail.valid?(email) && !::Person.exists?(email: email)
        email
      end

      def birthday(row)
        birthday = row[:birthday].to_s
        return '' unless birthday.present?

        DateTime.parse(birthday)
      rescue Date::Error
        ''
      end

      def gender(row)
        GENDERS[row[:gender].to_s]
      end

      def language(row)
        LANGUAGES[row[:language].to_s]
      end

      def set_role(row, person)
        person.roles.destroy_all
        person.roles.build(group: bluemlisalp_member_group(row),
                           type: role_type(row),
                           created_at: role_created_at(row),
                           deleted_at: role_deleted_at(row))
      end

      def bluemlisalp_member_group(row)
        ::Group::SektionsMitglieder.find_by(parent: bluemlisalp_group(row))
      end

      def bluemlisalp_group(row)
        navision_id = row[:group_navision_id].to_i
        ::Group::Sektion.find_by(navision_id: navision_id)
      end

      def role_type(row)
        ROLE_TYPES[row[:role_type].to_s]
      end

      def role_created_at(row)
        role_created_at = row[:role_created_at].to_s
        return nil unless role_created_at.to_s.present?

        DateTime.parse(role_created_at)
      rescue Date::Error
        nil
      end

      def role_deleted_at(row)
        role_deleted_at = row[:role_deleted_at].to_s
        return nil unless member_type(row) == 'Ausgetreten' && role_deleted_at.to_s.present?

        DateTime.parse(role_deleted_at)
      rescue Date::Error
        nil
      end

      def member_type(row)
        row[:member_type].to_s
      end

    end
  end
end
