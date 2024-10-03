# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class MembershipsImporter < ImporterBase

    def initialize(output: $stdout, csv_source:, csv_report: , failed_person_ids: [])
      super
      @rows_filter = { role: /^Mitglied \(Stammsektion\).+/ }
    end

    private

    def process_row(row)
      super(row)
      # 0. skip person if in failed_person_ids
      # 1. find person
      #   a. if person not found, skip row, report error
      # 2. really_destroy all existing membership roles
      # 3. 
      #unless skipped_row?(row)
        #import!(row, "memberships") do |row|
          #MembershipEntry.new(row)
        #end
      #end
    end
  end
end
