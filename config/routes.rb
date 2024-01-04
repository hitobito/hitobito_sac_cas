# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


Rails.application.routes.draw do

  extend LanguageRouteScope

  language_scope do
    # Define wagon routes here

    get '/people/:id/membership' => 'people/membership#show', as: 'membership'
    get '/verify_membership/:verify_token' => 'people/membership/verify#show',
        as: 'verify_membership'

    resources :groups, only: [] do
      post 'self_inscription/confirm' => 'groups/self_inscription#confirm'

      namespace :people do
        namespace :neuanmeldungen do
          resource :approves, only: [:new, :create]
          resource :rejects, only: [:new, :create]
        end
      end
    end
  end
end
