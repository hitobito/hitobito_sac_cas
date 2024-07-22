# frozen_string_literal: true

class SacImports::CsvReport

  def initialize(sac_import_name, headers)
    timestamp = Time.zone.now.strftime("%Y-%m-%d-%H:%M")
    init_csv(sac_import_name, headers, timestamp)
  end

  def append_row(row)
  end

  private

  def log_dir
    log_dir = Rails.root.join("log", "sac_imports")
    log_dir.mkpath
    log_dir
  end

  def init_csv(sac_import_name, headers, timestamp)
    file_path = "#{log_dir}#{sac_import_name}_#{timestamp}.csv"
    CSV.open(file_path, "wb") do |csv|
      csv << headers
    end
  end

end
