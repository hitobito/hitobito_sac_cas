# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Doorkeeper
  module AuthorizationsController
    extend ActiveSupport::Concern

    # In the SAC wagon, we require the user to have at least one active role.
    # If the user has no roles, redirect them to the BasicLogin self-registration page.
    # Once the user has registered, they will be redirected back to the OAuth authorization page.
    # We need to pass the current request URL to the self-registration controller so it can redirect
    # back with the correct query params of the original request after completing the onboarding.
    def new
      return super if current_user.nil? || current_user.root? || current_user.roles.any?

      redirect_to group_self_registration_path(
        group_id: Group::AboBasicLogin.first,
        completion_redirect_path: authorization_path_without_prompt
      )
    end

    private

    def authorization_path_without_prompt
      uri = URI.parse(request.url)
      query = Rack::Utils.parse_query(uri.query)
      uri.query = Rack::Utils.build_query(query.except("prompt"))
      uri.request_uri
    end
  end
end
