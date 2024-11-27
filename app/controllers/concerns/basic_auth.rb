# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module BasicAuth
  extend ActiveSupport::Concern

  included do
    http_basic_authenticate_with(name: Settings.basic_auth.username, password: Settings.basic_auth.password)
  end
end
