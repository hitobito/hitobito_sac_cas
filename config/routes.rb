# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

Rails.application.routes.draw do
  extend LanguageRouteScope

  language_scope do
    # Define wagon routes here

    get "/people/:id/membership" => "people/membership#show", :as => "membership"
    put "/people/:id/sac_family_main_person" => "people/sac_family_main_person#update", :as => "sac_family_main_person"

    get "/people/query_external_training" => "person/query_external_training#index",
      :as => :query_external_training

    resource :email_check, only: [:create]

    resources :event_levels, module: "event", controller: "levels", except: [:show]

    resources :external_invoices, only: [:show], module: :people, param: :invoice_id

    resources :groups, only: [] do
      resources :sac_membership_configs, except: [:destroy]
      resources :sac_section_membership_configs, except: [:destroy]
      resources :yearly_membership_invoices, only: [:create, :new], module: :people

      resources :events, only: [] do
        scope module: "event" do
          resource :key_data_sheets, only: [:create], module: :courses
          resource :mail_dispatch, only: [:create], module: :courses
          resource :leader_settlement_pdfs, only: [:create], module: :courses
          resources :participations, only: [] do
            put :summon, on: :member
            resources :invoices, only: [:new, :create], module: :courses do
              collection do
                get :recalculate
              end
            end
          end

          put "state" => "courses/state#update", :on => :member
        end
      end

      resources :people, only: [] do
        resources :external_trainings, except: [:edit, :show, :index]
        resources :membership_invoices, only: [:create, :new], module: :people
        resources :abo_magazin_invoices, only: [:create, :new], module: :people
        resources :sac_remarks, only: %i[index edit update], module: :person
        resource :join_zusatzsektion, module: :memberships, only: [:show, :create]
        resource :switch_stammsektion, module: :memberships, only: [:show, :create]
        resource :terminate_sac_membership, module: :memberships, only: [:show, :create]
        resources :roles, only: [] do
          resource :leave_zusatzsektion, module: :memberships, only: [:show, :create]
          resource :undo_termination, module: :memberships, only: [:new, :create]
        end
        member do
          get "external_invoices" => "people/external_invoices#index"
          post "external_invoices/:invoice_id/cancel" => "people/external_invoices#cancel", :as => "cancel_external_invoices_group_people"
          # Test route to check invoice positions for a person.
          # Remove once invoices are sent to abacus
          get "membership_invoice_positions" => "people/membership_invoice_positions#show"
        end
      end

      namespace :people do
        namespace :neuanmeldungen do
          resource :approves, only: [:new, :create]
          resource :rejects, only: [:new, :create]
        end
      end

      resources :mitglieder_exports, only: [:create],
        constraints: {format: "csv"},
        defaults: {format: "csv"}
    end

    resources :termination_reasons, except: [:show]
    resources :section_offerings, except: [:show]
    resources :course_compensation_rates, except: [:show]
    resources :course_compensation_categories, except: [:show]

    resources :cost_centers
    resources :cost_units

    resources :event_kinds, module: "event", controller: "kinds", only: [] do
      put :push_down, on: :member
    end

    resources :event_kind_categories, module: "event", controller: "kind_categories", only: [] do
      put :push_down, on: :member
    end

    scope path: ApplicationResource.endpoint_namespace, module: :json_api,
      constraints: {format: "jsonapi"}, defaults: {format: "jsonapi"} do
      resources :external_invoices, only: [:index, :show, :update]
      resources :event_levels, module: :event, controller: :levels, only: [:index, :show]
    end
  end
end
