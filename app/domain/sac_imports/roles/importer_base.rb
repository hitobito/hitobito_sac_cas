# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class ImporterBase

    def initialize(output: $stdout, csv_source:, csv_report: , failed_person_ids: [])
      @output = output
      @csv_report = csv_report
      @failed_person_ids = failed_person_ids
      @data = csv_source.rows(filter: @rows_filter)
    end

    def create
      @data.each do |row|
        process_row(row)
      end
    end

    private

    def process_row(row)
      person = fetch_person(row)
      return unless person
    end

    def fetch_person(row)
      if @failed_person_ids.include?(row[:navision_id])
        report_person_failed_before(row)
        return
      end

      person = Person.find_by(id: row[:navision_id])
      return person unless person.nil?

      report_person_not_found(row)
      nil
    end

    def report_person_not_found(row)
      @failed_person_ids << row[:navision_id]
      add_report_row(row, errors: "Person not found in hitobito")
    end

    def report_person_failed_before(row)
      add_report_row(row, errors: "A previous role could not be imported for this person, skipping")
    end

    def add_report_row(row, errors: nil, message: nil)
      @csv_report.add_row({
        navision_id: row[:navision_id],
        person_name: row[:person_name],
        valid_from: row[:valid_from],
        valid_until: row[:valid_until],
        target_group: target_group_path(row),
        target_role: row[:role],
        errors: errors,
        message: message
      })
    end

    def target_group_path(row)
      group_keys = %i[layer_type group_level1 group_level2 group_level3 group_level4]
      group_keys.map { |key| row[key] }.compact.join(" > ")
    end
  end
end
