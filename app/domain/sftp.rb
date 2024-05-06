# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'net/sftp'

class Sftp
  ConnectionError = Class.new(StandardError)

  def initialize(config)
    @config = config
  end

  def upload_file(data, file_path)
    handle = @connection.open!(file_path, 'w')
    @connection.write!(handle, 0, data)
    @connection.close(handle)
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

  def connection
    @connection ||= Net::SFTP.start(@config.host, @config.user, options).tap(&:connect!)
  rescue => e
    raise ConnectionError.new(e)
  end

  def options
    credentials = if @config.private_key.present?
                    { key_data: [@config.private_key] }
                  else
                    { password: @config.password }
                  end
    credentials.merge(non_interactive: true, port: @config.port).compact
  end
end
