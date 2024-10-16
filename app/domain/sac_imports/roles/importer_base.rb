# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class ImporterBase

    SECTION_OR_ORTSGRUPPE_GROUP_TYPE_NAMES = [Group::Sektion.sti_name,
      Group::Ortsgruppe.sti_name].freeze

    def initialize(csv_source:, csv_report:, output: $stdout, failed_person_ids: [])
      @output = output
      @csv_report = csv_report
      @failed_person_ids = failed_person_ids
      @data = csv_source.rows(filter: @rows_filter)
      @navision_import_group = fetch_navision_import_group
      @csv_source_person_ids = collect_csv_source_person_ids
    end

    def create
      @data.each do |row|
        process_row(row)
      end
    end

    private

    def process_row(row)
      return unless dates_valid?(row)
      person = fetch_person(row)
      return unless person

      if yield(person)
        clear_navision_import_role(person)
      end
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

    def dates_valid?(row)
      valid_until = Date.parse(row[:valid_until])
      valid_from = Date.parse(row[:valid_from])
      return true if valid_from < valid_until

      report(row, nil, error: "valid_from (GültigAb) cannot be before valid_until (GültigBis)")
      false
    end

    def save_role!(role, row)
      begin
        role.save!(context: :import)
      rescue ActiveRecord::RecordInvalid
        report(row, nil, error: "Hitobito Role: " + role.errors.full_messages.join(", "))
        return nil
      end
      role
    end

    def clear_navision_import_role(person)
      person.roles.where(group: @navision_import_group).delete_all
    end

    def fetch_navision_import_group
      Group::ExterneKontakte
        .find_by(name: "Navision Import", parent: Group.root)
    end

    def report_person_not_found(row)
      report(row, nil, error: "Person not found in hitobito")
    end

    def report_person_failed_before(row)
      report(row, nil, error: "A previous role could not be imported for this person, skipping")
    end

    def report(row, person, message: nil, warning: nil, error: nil)
      @failed_person_ids << row[:navision_id] if error.present?
      output_message = "#{row[:navision_id]} (#{row[:person_name]}): "
      output_message << if error.present?
        "❌ #{error}\n"
      else
        "✅ #{message || warning}\n"
      end

      @output.print(output_message)
      add_report_row(row, message: message, warning: warning, error: error)
    end

    def add_report_row(row, message: nil, warning: nil, error: nil)
      @csv_report.add_row({
        navision_id: row[:navision_id],
        person_name: row[:person_name],
        valid_from: row[:valid_from],
        valid_until: row[:valid_until],
        target_group: target_group_path(row),
        target_role: row[:role],
        message: message,
        warning: warning,
        error: error
      })
    end

    def collect_csv_source_person_ids
      @data.map { |row| row[:navision_id].to_i }.uniq
    end

    def target_group_path(row)
      group_keys = %i[layer_type group_level1 group_level2 group_level3 group_level4]
      group_keys.map { |key| row[key] }.compact.join(" > ")
    end

    def fetch_membership_group(row, person)
      group_name = extract_membership_group_name(row)
      parent_group = Group.find_by(name: group_name, type: SECTION_OR_ORTSGRUPPE_GROUP_TYPE_NAMES)
      if parent_group
        return Group::SektionsMitglieder.find_by(parent_id: parent_group.id)
      end

      report(row, person, error: "No Section/Ortsgruppe group found for '#{group_name}'")
      nil
    end

    def extract_membership_group_name(row)
      # if ortsgruppe
      if row[:group_level3] == "Mitglieder"
        return row[:group_level2]
      end

      row[:group_level1]
    end
  end
end
