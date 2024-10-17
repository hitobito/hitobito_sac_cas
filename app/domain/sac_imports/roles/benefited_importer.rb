# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class BenefitedImporter < ImporterBase
    def initialize(csv_source:, csv_report:, output: $stdout, failed_person_ids: [])
      @rows_filter = {role: /^Begünstigt$/}
      super
    end

    def create
      delete_existing_benefited_roles
      super
    end

    private

    def process_row(row)
      super do |person|
        membership_group = fetch_membership_group(row, person)
        return false if membership_group.blank?

        role = create_benefited_role(row, membership_group, person)
        return false if role.blank?

        report(row, person, message: "Benefited role created")
        true
      end
    end

    def create_benefited_role(row, membership_group, person)
      role = Group::SektionsMitglieder::Beguenstigt
        .new(group: membership_group,
          person: person,
          start_on: row[:valid_from])

      save_role!(role, row)
    end

    def delete_existing_benefited_roles
      roles = Group::SektionsMitglieder::Beguenstigt.with_inactive.where(person_id: @csv_source_person_ids)
      roles.delete_all
    end
  end
end
