# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class ImporterBase

    def initialize(output, csv_report, failed_person_ids: [])
      @output = output
      @source_file = source_file
      @csv_report = csv_report
      @failed_person_ids = failed_person_ids
    end

    def create
      data = @source_file.rows(filter: @rows_filter)
      data.each do |row|
        process_row(row)
      end
    end

    private

    def process_row(row)
      person = fetch_person(row)
      return unless person
    end

    def fetch_person(row)
      person = Person.find_by(id: row[:navision_id])
      return person unless person.nil?

      @failed_person_ids << row[:navision_id]
      @csv_report.add_row({
        navision_membership_number: row[:navision_id],
        navision_name: row[:navision_name],
        errors: entry.errors
      })
    end
  end
end
