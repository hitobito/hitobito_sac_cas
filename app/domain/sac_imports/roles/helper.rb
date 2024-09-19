module SacImports::Roles::Helper
  def import!(row, layer)
    @output.print("#{row[:navision_id]} (#{row[:name]}) #{layer}:")

    entry = yield(row)

    @output.print(entry.valid? ? " ✅\n" : " ❌ #{entry.errors}\n")

    if entry.valid?
      entry.import!
    else
      entry.skipped?
      @csv_report.add_row({
        navision_id: row[:navision_id],
        navision_name: row[:name],
        group: [row[:group_lvl_1], row[:group_lvl_2], row[:group_lvl_3], row[:group_lvl_4]].compact.join(" > "),
        layer: layer,
        errors: entry.errors
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
