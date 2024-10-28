# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class Nav22NonMembershipImporter < ImporterBase
    include Nav22Shared

    private

    def process_row(row)
      super do |person|
        parent = find_anchor(row) # root or sektion/ortsgruppe
        return if /ERROR/.match?(row[:role]) # skip error rows

        hierarchy = group_hierarchy(row, parent)

        group = find_group(row, *hierarchy, parent:)
        # binding.pry unless group || row[:role] == "Mitglied" && row[:group_level1] == "SAC Geschäftsleitung" || row[:role] =~ /ERROR/ || row[:role_description] =~ /(Klettern|Senior)/ || row[:group_level1] =~ /SAC Bellinzona/
        group ||
          report(row, person, error: "Group '#{group_hierarchy_to_s(row, parent)}' not found") && next

        role_type = find_role_type(group, row[:role]) ||
          report(row, person, error: "Role type '#{row[:role]}' not found in '#{group.decorate.label_with_parent}'") && next

        role = create_role(row, group, person, role_type, row[:role_description])
        status = (role.created_at < 1.minute.ago) ? :created : :updated
        report(row, person, message: "Role '#{role_type.label}' #{status} in '#{group.decorate.label_with_parent}'")
      rescue ActiveRecord::RecordInvalid => e
        report(row, person, message: "Role '#{role_type.label}' in '#{group.decorate.label_with_parent}'", error: e.message)
      rescue => e
        report(row, person, message: "Role '#{role_type.label}' in '#{group.decorate.label_with_parent}'", error: "#{e.message}, #{e.backtrace.first}")
      end
    end

    def find_or_create(...) = find(...) # we don't create groups in this importer, just find them

    def create_role(row, group, person, role_type, role_label)
      role_type
        .unscoped
        .where(group: group,
          person: person,
          start_on: row[:valid_from],
          end_on: row[:valid_until])
        .first_or_create!(label: role_label)
    end

    def find_role_type(group, role_label)
      group.role_types.find { |role_type| role_type.label == role_label }
    end
  end
end
