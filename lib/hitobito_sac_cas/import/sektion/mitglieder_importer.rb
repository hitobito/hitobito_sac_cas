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

      attr_reader :output, :path, :errors, :invalid_emails

      def initialize(path, output: STDOUT)
        @path = path
        @output = output
        @errors = []
        @invalid_emails = []
      end

      def import!
        with_file do
          each_row { |row| import_row(row) }
          print_summary
          print_errors
          print_invalid_emails
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
        id = row[:group_navision_id].to_i
        member = ::Import::Sektion::Mitglied.new(row, group: group(id), emails: existing_emails)

        if member.valid?
          import_person(member)
        elsif only_invalid_email?(member)
          import_person_without_email(member)
        else
          @errors << member.errors
        end
      end

      def import_person(member)
        member.import!
        existing_emails << member.email if member.email
        output.puts "Finished importing #{member}"
      rescue ActiveRecord::RecordInvalid => e
        @errors << "CAN NOT IMPORT ROW WITH NAVISION ID: #{row[:navision_id]}\n#{e.message}"
      end

      def import_person_without_email(member)
        @invalid_emails << "#{member}: #{member.email}"
        member.person.email = nil
        import_person(member)
      end

      def only_invalid_email?(member)
        member.person.errors.attribute_names == [:email]
      end

      def without_query_logging
        old_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = nil
        yield
        ActiveRecord::Base.logger = old_logger
      end

      def group(id)
        @groups ||= {}
        @groups[id] ||= ::Group::SektionsMitglieder
          .joins(:parent).find_by(parent: { navision_id: id })
      end

      def print_summary
        @groups.each_value do |group|
          active = group.roles.count
          deleted = group.roles.deleted.count
          output.puts "#{group} hat #{active} aktive, #{deleted} inaktive Rollen"
        end
      end

      def print_errors
        output_list("Die folgenden #{errors.size} Personen waren ungültig:", errors)
      end

      def print_invalid_emails
        output_list("Die folgenden #{invalid_emails.size} Emails waren ungültig:", invalid_emails)
      end

      def output_list(text, list)
        return if list.empty?

        output.puts text
        list.each { |item| output.puts " #{item}" }
      end
    end
  end
end
