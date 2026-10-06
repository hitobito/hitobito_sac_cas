# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "csv"

module TTY
  class People
    # Takes a csv of hard bounced email addresses, removes the primary email of people who did not
    # log in during the last year, switches all of them to print correspondence and writes a report
    # with the actions taken per person.
    class CleanupHardBounces
      prepend TTY::Command

      self.description = "Cleanup hard bounces, see hitobito/hitobito_sac_cas#2644"

      INPUT_HEADERS = [:person_id, :email, :bounce_type, :bounce_reason].freeze
      OUTPUT_HEADERS = [
        :person_id, :email, :bounce_type, :bounce_reason, :last_sign_in_at,
        :email_removed, :correspondence_before, :correspondence_after, :status, :details
      ].freeze

      # people without a login since this period lose their primary email
      INACTIVITY_PERIOD = 365.days

      Result = Data.define(*OUTPUT_HEADERS) do
        def to_csv_row = deconstruct
      end

      def run(input_path = nil, output_path: nil, dry_run: false)
        @input_path = input_path.presence || ask_for_input_path
        @output_path = output_path.presence || default_output_path

        rows = read_input
        puts info("Processing #{rows.size} people from #{@input_path}")

        results = process(rows, dry_run:)

        write_output(results)
        print_summary(results)
      end

      private

      def process(rows, dry_run:)
        results = []
        # requires_new so that a dry run is rolled back even within a surrounding transaction
        Person.transaction(requires_new: true) do
          rows.each_with_index do |row, index|
            print "\rPerson #{index + 1} of #{rows.size}"
            results << process_row(row)
          end
          puts

          if dry_run
            puts warning("Dry run: rolling back all changes")
            raise ActiveRecord::Rollback
          end
        end
        results
      end

      def process_row(row)
        person = Person.find_by(id: row[:person_id])
        return person_not_found(row) if person.nil?

        correspondence_before = person.correspondence
        keep_email = keep_email_reason(person, row[:email])
        person.email = nil if keep_email.nil?
        person.correspondence = "print"
        changed = person.changed?

        if person.save
          result(row, person, correspondence_before:,
            email_removed: keep_email.nil?,
            correspondence_after: person.correspondence,
            status: changed ? "updated" : "unchanged",
            details: keep_email)
        else
          failed(row, person, correspondence_before:)
        end
      end

      def failed(row, person, correspondence_before:)
        result(row, person, correspondence_before:,
          email_removed: false,
          correspondence_after: correspondence_before,
          status: "error",
          details: person.errors.full_messages.join("; "))
      end

      # Returns the reason to keep the primary email, or nil if it is to be removed.
      def keep_email_reason(person, bounced_email)
        return "no primary email" if person.email.blank?

        if bounced_email.present? && !person.email.casecmp?(bounced_email.strip)
          return "primary email #{person.email} differs from bounced email"
        end

        last_sign_in_at = person.last_sign_in_at
        if last_sign_in_at.present? && last_sign_in_at > INACTIVITY_PERIOD.ago
          "signed in at #{last_sign_in_at.to_fs(:db)}"
        end
      end

      def result(row, person, **attrs)
        Result.new(
          person_id: row[:person_id],
          email: row[:email],
          bounce_type: row[:bounce_type],
          bounce_reason: row[:bounce_reason],
          last_sign_in_at: person&.last_sign_in_at&.to_fs(:db),
          **attrs
        )
      end

      def person_not_found(row)
        result(row, nil,
          email_removed: false,
          correspondence_before: nil,
          correspondence_after: nil,
          status: "person_not_found",
          details: nil)
      end

      def read_input
        raise "Input file not found: #{@input_path}" unless File.exist?(@input_path)

        table = CSV.read(@input_path, headers: true, header_converters: :symbol,
          col_sep: column_separator, encoding: "bom|utf-8")
        missing = INPUT_HEADERS - table.headers
        if missing.any?
          raise "Missing headers in #{@input_path}: #{missing.join(", ")}"
        end

        table
      end

      # csv exports from excel are commonly separated by semicolons
      def column_separator
        header_line = File.open(@input_path, "r:bom|utf-8", &:readline)
        (header_line.count(";") > header_line.count(",")) ? ";" : ","
      end

      def write_output(results)
        CSV.open(@output_path, "w") do |csv|
          csv << OUTPUT_HEADERS
          results.each { csv << _1.to_csv_row }
        end
        puts info("Wrote #{results.size} rows to #{@output_path}")
      end

      def print_summary(results)
        puts info("Summary")
        results.group_by(&:status).sort_by(&:first).each do |status, rows|
          puts "  #{status}: #{rows.size}"
        end
        puts "  emails removed: #{results.count(&:email_removed)}"
        results.select { _1.status == "error" }.each do |failure|
          puts error("  #{failure.person_id}: #{failure.details}")
        end
      end

      def ask_for_input_path
        print "Path to the csv (#{INPUT_HEADERS.join(", ")}): "
        $stdin.gets.to_s.strip.delete_prefix('"').delete_suffix('"')
      end

      def default_output_path
        timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")

        Rails.root.join("tmp", "cleanup_hard_bounces-#{timestamp}.csv")
      end
    end
  end
end
