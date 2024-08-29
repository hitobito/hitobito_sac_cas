# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Wso2LegacyPasswordHelper
  def generate_wso2_legacy_password_hash(password, salt = nil)
    digest_input = salt ? password + salt : password
    sha256 = OpenSSL::Digest.new("SHA256")
    hash = sha256.digest(digest_input)
    Base64.strict_encode64(hash)
  end
end

RSpec.configure do |config|
  config.include Wso2LegacyPasswordHelper
end
