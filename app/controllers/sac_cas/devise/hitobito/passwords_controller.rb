# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Devise::Hitobito::PasswordsController
  def successfully_sent?(resource)
    if resource.login?
      super
    else
      flash[:notice] = I18n.translate("devise.failure.signin_not_allowed")
    end
  end
end
