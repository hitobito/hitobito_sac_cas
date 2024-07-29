# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class MembershipYearsReport
    REPORT_HEADERS = [
      :membership_number, :person_name,
      :navision_membership_years, :hitobito_membership_years,
      :diff, :errors
    ].freeze

    def initialize(output: $stdout)
      @output = output
      @source_file = CsvSourceFile.new(:NAV2)
      @csv_report = CsvReport.new(:'6_membership_years_report', REPORT_HEADERS)
    end

    def create
      data = @source_file.rows
      fetch_hitobito_people(data)
      data.each do |row|
        process_row(row)
      end
    end

    private

    def process_row(row)
      person = @hitobito_people[row[:navision_id].to_i]
      @csv_report.add_row(
        {membership_number: row[:navision_id],
         person_name: row[:person_name],
         navision_membership_years: row[:navision_membership_years],
         hitobito_membership_years: person&.membership_years,
         diff: membership_years_diff(row[:navision_membership_years], person&.membership_years),
         errors: errors_for(person)}
      )
    end

    def fetch_hitobito_people(data)
      people_ids = data.pluck(:navision_id).compact
      @hitobito_people = Person.with_membership_years.where(id: people_ids).index_by(&:id)
    end

    def membership_years_diff(navision_years, hitobito_years)
      return nil if navision_years.blank? || hitobito_years.blank?

      navision_years.to_i - hitobito_years
    end

    def errors_for(person)
      [].tap do |errors|
        errors << "Person not found in hitobito" unless person
      end.join(", ").presence
    end
  end
end
