# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::CornercardApplicationsJob < BaseJob
  self.use_background_job_logging = true

  def perform
    return if sftp_config.blank?

    uploads = CornercardUpload.pending
    return if uploads.empty?

    xlsx_data = Export::Tabular::People::CornercardApplications.new(uploads).to_xlsx
    file_path = remote_file_path
    sftp.upload_file(xlsx_data, file_path)
    log_entry(uploads, file_path)
    uploads.update_all(uploaded_at: Time.current)
  end

  private

  def sftp
    @sftp ||= Sftp.new(sftp_config)
  end

  def sftp_config
    Settings.cornercard.config
  end

  def remote_file_path
    date = Date.current.strftime("%Y-%m-%d")
    "sac-cornercard-#{date}.xlsx"
  end

  def log_entry(uploads, file_path)
    HitobitoLogEntry.create!(
      category: "cornercard",
      level: "info",
      message: "Cornèrcard export: #{uploads.count} Anträge nach #{file_path} hochgeladen"
    )
  end
end
