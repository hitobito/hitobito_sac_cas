# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('lib', 'import', 'xlsx_reader.rb')

module Import
  class PeopleImporter

    class_attribute :headers, default: {
      navision_id: 'Mitgliedernummer',
      person_type: 'Personentyp',
      salutation: 'Anredecode',
      name: 'Name',
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
      language: 'Sprachcode'
    }.freeze

    class_attribute :sheet_name, default: 'conv'

    attr_reader :path, :skip_existing, :output, :errors, :invalid_emails, :processed_rows_count

    def initialize(path, skip_existing: false, output: $stdout)
      @path = path
      @skip_existing = skip_existing
      @output = output
      @errors = []
      @invalid_emails = []
      @processed_rows_count = 0
    end

    def import!
      with_file do
        each_row do |row|
          next if skip?(row)

          import_row(row)
        end
      end
    ensure
      print_errors
      print_invalid_emails
      print_summary
    end

    def each_row
      without_query_logging do
        Import::XlsxReader.read(path, sheet_name, headers: headers) do |row|
          yield row unless row.compact.empty?
          @processed_rows_count += 1
        end
      end
    end

    private

    def with_file
      return yield if path.exist?

      output.puts "\nFAILED: Cannot read #{path.to_path}"
    end

    def navision_id(row)
      row[:navision_id]
    end

    def existing_emails
      @existing_emails ||= ::Person.pluck('DISTINCT(email)').compact.sort
    end

    def existing_people_ids
      @existing_people_ids ||= Set.new(::Person.pluck(:id))
    end

    def skip?(row)
      skip_existing && existing_people_ids.include?(navision_id(row).to_i)
    end

    def import_row(row)
      entry = ::Import::PersonEntry.new(row, group: contact_role_group, emails: existing_emails)

      if entry.valid?
        import_person(entry)
      elsif only_invalid_email?(entry)
        import_person_without_email(entry)
      else
        errors << entry.errors
      end
    end

    def import_person(entry)
      entry.import!
      existing_emails << entry.email if entry.email
      output.puts "Finished importing #{entry}"
    rescue ActiveRecord::RecordInvalid => e
      errors << "CAN NOT IMPORT ROW WITH NAVISION ID: #{navision_id(row).inspect}\n#{e.message}"
    end

    def import_person_without_email(entry)
      @invalid_emails << "#{entry}: #{entry.email}"
      entry.person.email = nil
      import_person(entry)
    end

    def only_invalid_email?(entry)
      entry.person.errors.attribute_names == [:email]
    end

    def contact_role_group
      @contact_role_group ||= Group::ExterneKontakte.find_or_create_by!(
        name: 'Navision Import',
        parent_id: Group::SacCas.first!.id
      )
    end

    def without_query_logging
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      yield
      ActiveRecord::Base.logger = old_logger
    end

    def print_summary
      output.puts "\nProcessed #{@processed_rows_count} rows"
      count = contact_role_group.roles.count
      output.puts "#{contact_role_group} hat #{count} Rollen"
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

    def without_reset_primary_group
      Role.skip_callback(:destroy, :after, :reset_primary_group, raise: false)
      yield
    ensure
      Role.set_callback(:destroy, :after, :reset_primary_group)
    end
  end
end
