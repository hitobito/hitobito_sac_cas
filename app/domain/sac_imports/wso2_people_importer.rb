# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class Wso2PeopleImporter
    REPORT_HEADERS = [
      :navision_id,
      :first_name,
      :last_name,
      :warnings,
      :errors
    ]

    def initialize(output: $stdout, debug: false)
      PaperTrail.enabled = false # disable versioning for imports
      @output = output
      @debug = debug
      @source_file = CsvSource.new(:WSO21)
      @csv_report = CsvReport.new(:"wso21-1_people", REPORT_HEADERS)
      @imported_people_ids = []
    end

    def create
      data = @source_file.rows.select
      @progress = Progress.new(data.size, silent: @debug, output: @output)
      data.each do |row|
        process_row(row)
      end

      remove_navision_import_roles!

      @csv_report.finalize(output: @output)
    end

    private

    def basic_login_group
      @basic_login_group ||= Group::AboBasicLogin.first!
    end

    def abo_group
      @abo_group ||= Group::AboTourenPortal.first!
    end

    def navision_import_group
      @navision_import_group ||= Group::ExterneKontakte.find_by!(name: "Navision Import")
    end

    def remove_navision_import_roles!
      navision_import_group.roles.where(person_id: @imported_people_ids).delete_all
    end

    def process_row(row)
      @progress.step
      @output.print("#{row[:navision_id]} (#{row[:email]}):") if @debug
      entry = Wso2::PersonEntry.new(row, basic_login_group, abo_group, navision_import_group)
      @output.print(entry.valid? ? " ✅\n" : " ❌ #{entry.error_messages}  --- ETA:#{@progress.eta}\n") if @debug
      if entry.valid?
        entry.import!
        @imported_people_ids << entry.person.id
        if entry.warning
          @csv_report.add_row({
            navision_id: row[:navision_id],
            first_name: row[:first_name],
            last_name: row[:last_name],
            warnings: entry.warning
          })
        end
      else
        @csv_report.add_row({
          navision_id: row[:navision_id],
          first_name: row[:first_name],
          last_name: row[:last_name],
          errors: entry.error_messages
        })
      end
    end
  end
end
