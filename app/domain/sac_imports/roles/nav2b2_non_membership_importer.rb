# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class Nav2b2NonMembershipImporter < Nav2bBase
    private

    def process_row(row)
      super do |person|
        parent = find_anchor(row) # root or sektion/ortsgruppe
        return if /ERROR/.match?(row.role) # skip error rows

        hierarchy = group_hierarchy(row, parent)

        group = find_group(row, *hierarchy, parent:)
        # binding.pry unless group || row.role == "Mitglied" && row.group_level1 == "SAC Geschäftsleitung" || row.role =~ /ERROR/ || row.role_description =~ /(Klettern|Senior)/ || row.group_level1 =~ /SAC Bellinzona/
        group ||
          report(row, person, error: "Group '#{row.group_path}' not found") && next

        role_type = find_role_type(group, row.role) ||
          report(row, person, error: "Role type '#{row.role}' not found in '#{group.decorate.label_with_parent}'") && next

        create_role(row, group, person, role_type, row.role_description)
        # report(row, person, message: "Role '#{role_type.label}' created in '#{group.decorate
        #
      rescue => e
        log(row, person, role_type, group, error: "#{e.message}, #{e.backtrace.first}")
      end
    end

    def find_or_create(...) = find(...) # we don't create groups in this importer, just find them

    def create_role(row, group, person, role_type, role_label)
      role = role_type
        .unscoped
        .where(group: group,
          person: person,
          start_on: row.valid_from,
          end_on: row.valid_until)
        .first_or_initialize(label: role_label)
      role.write_attribute(:terminated, true) if role_type.terminatable && row.terminated?
      role.save!(context: :import) if role.new_record?
    rescue ActiveRecord::RecordInvalid => e
      if e.message =~ /Person muss mindestens eine aktive Qualifikation besitzen/ &&
          e.record.is_a?(Group::SektionsTourenUndKurse::Tourenleiter)
        # handle special case where a Tourenleiter role is created without a currently valid qualification
        log(row, person, role_type, group,
          warning: "Person has no valid qualification for Tourenleiter role, created TourenleiterOhneQualifikation instead")
        create_role(row, group, person, Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation, role_label)
      else
        log(row, person, role_type, group, error: e.message)
      end
    end

    def find_role_type(group, role_label)
      group.role_types.find { |role_type| role_type.label == role_label }
    end

    def log(row, person, role_type, group, warning: nil, error: nil)
      message = "Role '#{role_type.label}' in '#{group.decorate.label_with_parent}'"
      report(row, person, message:, warning:, error:)
    end
  end
end
