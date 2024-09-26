#!/usr/bin/env ruby

require "csv"

input_file = ARGV[0]

csv = CSV.table(input_file, headers: true, converters: [], header_converters: [])
puts csv.headers.map { |v| "\"#{v}\"" }.join(",")

csv.each do |row|
  row_data = []
  row.map do |field|
    value = field[1]
    row_data << if value.nil? || value == "" || value == "NULL"
      value.to_s
    else
      value.gsub!('"', '""') # quote " with "
      "\"#{value}\""
    end
  end
  puts row_data.join(",")
end
