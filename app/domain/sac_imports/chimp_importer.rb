# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  class ChimpImporter
    include LogCounts

    REPORT_HEADERS = [
      :email,
      :first_name,
      :last_name,
      :status,
      :warnings,
      :errors
    ].freeze

    attr_reader :output

    def initialize(output: $stdout)
      @output = output
      @csv_report = CsvReport.new(:"chimp-import", REPORT_HEADERS, output:)
    end

    def create
      chimp_1 = CsvSource.new(:CHIMP_1)
      chimp_2 = CsvSource.new(:CHIMP_2)
      chimp_3 = CsvSource.new(:CHIMP_3)

      list_newsletter = MailingList.find_by!(internal_key: SacCas::MAILING_LIST_SAC_NEWSLETTER_INTERNAL_KEY)
      list_sac_inside = MailingList.find_by!(internal_key: SacCas::MAILING_LIST_SAC_INSIDE_INTERNAL_KEY)
      list_tourenleiter = MailingList.find_by!(internal_key: SacCas::MAILING_LIST_TOURENLEITER_INTERNAL_KEY)

      total_lines = [chimp_1, chimp_2, chimp_3].sum(&:lines_count)
      progress = Progress.new(total_lines, title: "Mailchimp Subscriptions")

      @csv_report.log("Chimp 1 (Newsletter) has #{chimp_1.lines_count} lines")
      @csv_report.log("Chimp 2 (SAC Inside) has #{chimp_2.lines_count} lines")
      @csv_report.log("Chimp 3 (Tourenleiter) has #{chimp_3.lines_count} lines")
      @csv_report.log("Total lines: #{total_lines}")

      log_counts_delta(@csv_report,
        "Newsletter Subscribers" => list_newsletter.subscriptions.where(subscriber_type: "Person"),
        "SAC Inside Subscribers" => list_sac_inside.subscriptions.where(subscriber_type: "Person"),
        "Tourenleiter Subscribers" => list_tourenleiter.subscriptions.where(subscriber_type: "Person")) do
        import_subscribers(chimp_1, list_newsletter, progress)
        import_subscribers(chimp_2, list_sac_inside, progress)
        import_subscribers(chimp_3, list_tourenleiter, progress)
      end
    end

    private

    def import_subscribers(source, list, progress)
      report = CsvReport.new(source.source_name.to_s.downcase, REPORT_HEADERS, output: @output)

      source.rows do |row|
        progress.step
        email = row.email.downcase

        person = Person.find_by(email: email)

        next report_unknown_email(report, row) if person.nil?

        list.subscriptions.where(subscriber: person).first_or_create!
      end
    end

    def report_unknown_email(report, row)
      report.add_row({
        email: row.email,
        first_name: row.first_name,
        last_name: row.last_name,
        status: "error",
        errors: "Person with email not found"
      })
    end
  end
end
