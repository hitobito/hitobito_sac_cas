# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "net/sftp"

class Sftp
  ConnectionError = Class.new(StandardError)

  def initialize(config)
    @config = config
  end

  def upload_file(data, file_path)
    create_missing_directories(file_path) if create_directories?

    Tempfile.open("hitobito-sftp-upload", binmode: true) do |tempfile|
      tempfile.write(data)
      tempfile.close
      connection.upload!(tempfile.path, file_path)
    end
  end

  def create_remote_dir(name)
    connection.mkdir!(name)
  end

  def directory?(name)
    connection.file.directory?(name)
  rescue
    false
  end

  private

  def server_version
    connection.session.transport.server_version.version || "unknown"
  end

  # On AWS SFTP, directories are created automatically. On other servers,
  # we need to create them manually.
  def create_directories?
    !/AWS_SFTP/.match?(server_version)
  end

  def create_missing_directories(file_path)
    Pathname.new(file_path).dirname.descend do |directory_path|
      create_remote_dir(directory_path.to_s) unless directory?(directory_path.to_s)
    end
  end

  def connection
    @connection ||= Net::SFTP.start(@config.host, @config.user, options).tap(&:connect!)
  rescue => e
    raise ConnectionError.new(e)
  end

  def options
    credentials = if @config.private_key.present?
      {key_data: [@config.private_key]}
    else
      {password: @config.password}
    end
    credentials.merge(non_interactive: true, port: @config.port).compact
  end
end
