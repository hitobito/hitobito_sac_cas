# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::AsciiTable
  def initialize(data)
    @data = data
  end

  def to_s
    table = StringIO.new
    # Calculate column widths based on the length of the string representation of each cell
    column_widths = @data.transpose.map { |column|
      column.max_by { |cell| cell.to_s.length }
        .to_s.length + 1
    }

    # Format the table header
    header = @data.first.map.with_index do |cell, i|
      if i == 0
        cell.to_s.ljust(column_widths[i])
      else
        cell.to_s.rjust(column_widths[i] - 1)
      end
    end.join("|")
    table.puts(header)

    # Separate the header and body with a line
    table.puts(separator(header.length))

    # Format the table body
    @data[1..].each do |row|
      if row == "-"
        table << separator(header.length)
        next
      end

      row_formatted = row.map.with_index do |cell, i|
        if i == 0
          cell.to_s.ljust(column_widths[i])
        else
          cell.to_s.rjust(column_widths[i] - 1)
        end
      end
      table.puts(row_formatted.join("|"))
    end
    table.puts(separator(header.length))
    table.string
  end

  private

  def separator(length) = "-" * length
end
