# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::TableDisplays::People::LoginStatusColumn
  def required_model_attrs(_attr)
    super + [
      :wso2_legacy_password_hash,
      :wso2_legacy_password_salt
    ]
  end
end
