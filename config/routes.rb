# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


Rails.application.routes.draw do

  extend LanguageRouteScope

  language_scope do
    # Define wagon routes here

    get '/people/:id/membership' => 'people/membership#show', as: 'membership'
    get '/people/query_external_training' => 'person/query_external_training#index',
        as: :query_external_training

    resources :event_levels, module: 'event', controller: 'levels', except: [:show]

    resources :groups, only: [] do
      post 'self_inscription/confirm' => 'groups/self_inscription#confirm'
      resources :sac_membership_configs, except: [:destroy]
      resources :sac_section_membership_configs, except: [:destroy]

      resources :events, only: [] do
        scope module: 'event' do
          resources :participations, only: [] do
            put :summon, on: :member
          end
        end
      end

      resources :people, only: [] do
        resources :external_trainings, except: [:edit, :show, :index]
      end
      namespace :people do
        namespace :neuanmeldungen do
          resource :approves, only: [:new, :create]
          resource :rejects, only: [:new, :create]
        end
      end

      resources :mitglieder_exports, only: [:create],
                                     constraints: { format: 'csv' },
                                     defaults: { format: 'csv' }

      resources :events, only: [] do
        member do
          put  'state' => 'events/courses/state#update'
        end
      end
    end

    resources :cost_centers, except: [:show]
    resources :cost_units, except: [:show]

    resources :event_kinds, module: 'event', controller: 'kinds', only: [] do
      put :push_down, on: :member
    end

    resources :event_kind_categories, module: 'event', controller: 'kind_categories', only: [] do
      put :push_down, on: :member
    end
  end
end
