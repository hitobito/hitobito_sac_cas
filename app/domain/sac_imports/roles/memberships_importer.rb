# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class MembershipsImporter < ImporterBase

    def initialize(output: $stdout, csv_source:, csv_report: , failed_person_ids: [])
      @rows_filter = { role: /^Mitglied \(Stammsektion\).+/ }
      super
      @csv_source_person_ids = collect_csv_source_person_ids
    end
    
    def create
      destroy_existing_membership_roles
      super
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

    def destroy_existing_membership_roles
      role_types = SacCas::MITGLIED_ROLES.map(&:sti_name)
      membership_roles = Role.with_deleted.where(type: role_types, person_id: @csv_source_person_ids)
      membership_roles.delete_all
    end

    def collect_csv_source_person_ids
      @data.map { |row| row[:navision_id].to_i }.uniq
    end
  end
end
