# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('lib', 'import', 'xlsx_reader.rb')

module Import
  module Sektion
    class MitgliederImporter

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
        beitragskategorie: 'Kategorie',
        member_type: 'Mitgliederart',
        language: 'Sprachcode',
        role_created_at: 'Letztes Eintrittsdatum',
        role_deleted_at: 'Letztes Austrittsdatum'
      }.freeze

      attr_reader :output, :path, :errors

      def initialize(path, output: STDOUT)
        @path = path
        @output = output
        @errors = []
      end

      def import!
        with_file do
          each_row { |row| import_row(row) }
          print_errors
        end
      end

      def each_row
        without_query_logging do
          Import::XlsxReader.read(path, 'Data', headers: HEADERS) do |row|
            yield row unless row.compact.empty?
          end
        end
      end

      private

      def with_file
        return yield if path.exist?

        output.puts "\nFAILED: Cannot read #{path.to_path}"
      end

      def existing_emails
        @existing_emails ||= ::Person.pluck('DISTINCT(email)').compact.sort
      end

      def import_row(row)
        member = ::Import::Sektion::Mitglied.new(row, group: group(row), emails: existing_emails)

        if member.valid?
          import_person(member.person)
        else
          @errors << member.errors
        end
      end

      def import_person(person)
        person.roles.except(&:new_record).destroy_all
        person.phone_numbers.except(&:new_record).destroy_all
        person.save!
        existing_emails << person.email if person.email
        output.puts "Finished importing #{person.full_name} (#{person.id})"
      rescue ActiveRecord::RecordInvalid => e
        @errors << "CAN NOT IMPORT ROW WITH NAVISION ID: #{row[:navision_id]}\n#{e.message}"
      end

      def without_query_logging
        old_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = nil
        yield
        ActiveRecord::Base.logger = old_logger
      end

      def group(row)
        @groups ||= {}
        @groups.fetch(row[:group_navision_id].to_i) do
          navision_id = row[:group_navision_id].to_i
          parent = ::Group::Sektion.find_by(navision_id: navision_id)
          ::Group::SektionsMitglieder.find_by(parent: parent)
        end
      end

      def print_errors
        output.puts 'Die folgenden Personen konnten nicht importiert werden:' if errors.present?
        errors.each do |error|
          output.puts " #{error}"
        end
      end
    end
  end
end
