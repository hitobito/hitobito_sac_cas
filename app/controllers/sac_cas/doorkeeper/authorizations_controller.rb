# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Doorkeeper
  module AuthorizationsController
    def create
      return super unless current_user.roles.empty?

      # store the current path including all arguments in the session so we can redirect to it after the user has registered
      session[:wizard_completed_redirect] = request.fullpath
      redirect_to(group_self_registration_path(group_id: 8))
    end
  end
end
