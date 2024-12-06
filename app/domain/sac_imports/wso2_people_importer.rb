# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Wso2PeopleImporter
    include LogCounts

    REPORT_HEADERS = [
      :navision_id,
      :um_id,
      :first_name,
      :last_name,
      :status,
      :warnings,
      :errors
    ]

    UM_USER_NAME_LOG_HEADERS = [
      :hitobito_id,
      :um_user_name,
      :email
    ]

    def initialize(output: $stdout)
      PaperTrail.enabled = false # disable versioning for imports
      @output = output
      @source_file = CsvSource.new(:WSO21)
      @csv_report = CsvReport.new(:"wso21-1_people", REPORT_HEADERS, output:)
      @um_user_name_log = CsvReport.new(:"wso21-1_um_user_name_log",
        UM_USER_NAME_LOG_HEADERS, output:)
      @existing_emails = load_existing_emails
      basic_login_group # warm up to ensure group is present before forking threads
      abo_group # warm up to ensure group is present before forking threads
    end

    def create
      @csv_report.log("The file contains #{@source_file.lines_count} rows.")

      log_counts_delta(@csv_report,
        Group::AboBasicLogin::BasicLogin,
        Group::AboTourenPortal::Abonnent,
        Person.unscoped,
        "People with wso2 pass" => Person.where.not(wso2_legacy_password_hash: nil)) do
        data = @source_file.rows
        data = data.drop(1) if data.first&.navision_id == "ContactNo" # skip header row

        progress = Progress.new(data.size, title: "WSO2 People Import", output: @output)

        # Parallel.map(data, in_threads: Etc.nprocessors) do |row|
        data.each do |row|
          progress.step
          process_row(row)
        end
      end
      @csv_report.finalize
    end

    private

    def load_existing_emails
      Concurrent::Set.new(Person.select("lower(email) as email").distinct.pluck(:email))
    end

    def basic_login_group
      @basic_login_group ||= Group::AboBasicLogin.first!
    end

    def abo_group
      @abo_group ||= Group::AboTourenPortal.first!
    end

    def process_row(row)
      # @output.print("#{row.navision_id} (#{row.email}):")
      entry = Wso2::PersonEntry.new(row, basic_login_group, abo_group, @existing_emails)
      # @output.print(entry.valid? ? " ✅\n" : " ❌ #{entry.error_messages}\n")
      if entry.valid?
        entry.import!
        @um_user_name_log.add_row(
          hitobito_id: entry.person.id,
          um_user_name: row.um_user_name,
          email: row.email
        )
        if entry.warning
          @csv_report.add_row({
            navision_id: row.navision_id,
            um_id: row.um_id,
            first_name: row.first_name,
            last_name: row.last_name,
            warnings: entry.warning,
            status: "warning"
          })
        end
      else
        @output.puts("#{row.navision_id} (#{row.email}): ❌ #{entry.error_messages}")
        @csv_report.add_row({
          navision_id: row.navision_id,
          um_id: row.um_id,
          first_name: row.first_name,
          last_name: row.last_name,
          errors: entry.error_messages,
          status: "error"
        })
      end
    end
  end
end
