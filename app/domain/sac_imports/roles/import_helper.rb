# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles::ImportHelper
  def import!(row, layer)
    @output.print("#{row[:navision_id]} (#{row[:name]}) #{layer}:")

    if skipped_row?(row)
      @output.print(" ❌ Previously skipped\n")
      @csv_report.add_row({
        navision_id: row[:navision_id],
        navision_name: row[:name],
        group: [row[:group_lvl_1], row[:group_lvl_2], row[:group_lvl_3], row[:group_lvl_4]].compact.join(" > "),
        layer: layer,
        errors: "Previously skipped"
      })
      return
    end

    entry = yield(row)

    @output.print(entry.valid? ? " ✅\n" : " ❌ #{entry.errors}\n")

    if entry.valid?
      entry.import!
    else
      skip_row(row) if entry.skipped?
      @csv_report.add_row({
        navision_id: row[:navision_id],
        navision_name: row[:name],
        group: [row[:group_lvl_1], row[:group_lvl_2], row[:group_lvl_3], row[:group_lvl_4]].compact.join(" > "),
        layer: layer,
        errors: entry.errors,
        warnings: entry.warnings
      })
    end
  end

  def skip_row(row)
    @skipped_rows << row
  end

  def skipped_row?(row)
    @skipped_rows.include?(row)
  end
end
