# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Doorkeeper
  module AuthorizationsController
    extend ActiveSupport::Concern
    include SelfRegistrationRedirect

    OAUTH_PARAMS_NO_ROLES_KEY = :oauth_params_no_roles

    prepended do
      prepend_before_action :restore_oauth_params, only: :new
    end

    # In the SAC wagon, we require the user to have at least one active role.
    # If the user has no roles, redirect them to the BasicLogin self-registration page.
    # Once the user has registered, they will be redirected back to the OAuth authorization page.
    # We need to remember the original OAuth parameters so we can restore them after the user
    # has completed their self-registration.
    def new
      return super unless current_user.roles.empty?

      remember_oauth_params
      redirect_to_self_registration(self_registration_group.id, oauth_authorization_path)
    end

    private

    def remember_oauth_params
      session[OAUTH_PARAMS_NO_ROLES_KEY] = request.parameters
        .except(:controller, :action, :authenticity_token)
    end

    def restore_oauth_params
      request.parameters.merge!(session.delete(OAUTH_PARAMS_NO_ROLES_KEY) || {})
    end

    def self_registration_group = Group::AboBasicLogin.first
  end
end
