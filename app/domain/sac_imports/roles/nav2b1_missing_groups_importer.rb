# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class Nav2b1MissingGroupsImporter < Nav2bBase
    def create
      rows = @data.uniq do |row|
        # Check each hierarchy combination only once
        [row.layer_type, row.group_level1, row.group_level2, row.group_level3, row.group_level4]
      end

      @csv_report.log("The file contains #{rows.size} unique groups.")
      progress = SacImports::Progress.new(rows.size, title: title)

      rows.each do |row|
        progress.step
        process_row(row)
      end
    end

    private

    def dates_valid?(*) = true # we don't care about dates

    def process_row(row)
      parent = find_anchor(row) || # root or sektion/ortsgruppe
        report(row, nil, error: "#{row.layer_type} '#{row.group_level1}' not found") && return

      hierarchy = group_hierarchy(row, parent)
      hierarchy.each_with_index do |_, index|
        # check each sub-hierarchy level if it exists
        sub_hierarchy = hierarchy[0..index]
        find_group(row, *sub_hierarchy, parent: parent) ||
          report(row, nil, error: "Group '#{row.group_path}' not found") &&
            break
      end
    rescue ActiveRecord::RecordInvalid => e
      report(row, nil, message: "Group '#{row.group_path}'", error: e.message)
    rescue => e
      report(row, nil, message: "Group '#{row.group_path}'", error: "#{e.message}, #{e.backtrace.first}")
    end
  end
end
