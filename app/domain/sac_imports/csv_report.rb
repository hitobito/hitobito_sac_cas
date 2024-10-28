# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SacImports::CsvReport
  COLUMN_SEPARATOR = ";"

  def initialize(sac_import_name, headers)
    @start_time = Time.zone.now
    @timestamp = format_time(Time.zone.now)
    @sac_import_name = sac_import_name
    @headers = headers
    csv_init
    log("Started: #{@timestamp}")
  end

  def add_row(row)
    csv_append(row)
  end

  def log(line)
    File.write(log_file_path, "#{line}\n", mode: "a")
  end

  def finalize(output: $stdout)
    log(
      "Started: #{@timestamp}, " \
        "completed: #{format_time(Time.zone.now)}, " \
        "duration: #{format_duration}"
    )
    output.puts "\n\n\nReport generated in #{format_duration}."
    output.puts "Thank you for flying with SAC Imports."
    output.puts "Report written to #{csv_file_path}"
    output.puts "Log written to #{log_file_path}"
  end

  private

  def format_time(time) = time.strftime("%Y-%m-%d-%H%M")

  def format_duration = "#{(Time.zone.now - @start_time) / 60} minutes"

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
    row_content = row_content.with_indifferent_access
    row_content = @headers.map { |header| row_content[header] }
    CSV.open(csv_file_path, "ab", col_sep: COLUMN_SEPARATOR) do |csv|
      csv << row_content
    end
  end

  def csv_file_path
    @csv_file_path ||= "#{log_dir}/#{@sac_import_name}_#{@timestamp}.csv"
  end

  def log_file_path
    @log_file_path ||= "#{log_dir}/#{@sac_import_name}_#{@timestamp}.log"
  end
end
