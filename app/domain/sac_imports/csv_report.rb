# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SacImports::CsvReport
  COLUMN_SEPARATOR = ";"

  def initialize(sac_import_name, headers)
    @start_time = Time.zone.now
    @timestamp = Time.zone.now.strftime("%Y-%m-%d-%H:%M")
    @sac_import_name = sac_import_name
    @headers = headers
    csv_init
  end

  def add_row(row)
    csv_append(row)
  end

  def finalize(output: $stdout)
    output.puts "\n\n\nReport generated in #{(Time.zone.now - @start_time) / 60} minutes."
    output.puts "Thank you for flying with SAC Imports."
    output.puts "Report written to #{csv_file_path}"
  end

  private

  def log_dir
    @log_dir ||= create_log_dir
  end

  def create_log_dir
    log_dir = Rails.root.join("log", "sac_imports")
    log_dir.mkpath
    log_dir
  end

  def csv_init
    CSV.open(csv_file_path, "wb", col_sep: COLUMN_SEPARATOR) do |csv|
      csv << @headers
    end
  end

  def csv_append(row_content)
    row_content = @headers.map { |header| row_content[header] }
    CSV.open(csv_file_path, "ab", col_sep: COLUMN_SEPARATOR) do |csv|
      csv << row_content
    end
  end

  def csv_file_path
    @csv_file_path ||= "#{log_dir}/#{@sac_import_name}_#{@timestamp}.csv"
  end
end
