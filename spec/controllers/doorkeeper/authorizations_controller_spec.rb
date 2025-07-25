# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Doorkeeper::AuthorizationsController do
  let(:user) { people(:mitglied) }
  let(:app) { Oauth::Application.create!(name: "MyApp", redirect_uri: "urn:ietf:wg:oauth:2.0:oob") }
  let(:authorize_params) do
    {
      client_id: app.uid,
      redirect_uri: app.redirect_uri,
      response_type: "code",
      scope: "email",
      response_mode: "query",
      state: "xyz",
      nounce: "12345",
      locale: "de"
    }
  end

  before { sign_in(user) }

  describe "GET #new" do
    context "with active roles" do
      before { expect(user.roles).to be_present }

      it "renders the authorization form" do
        get :new, params: authorize_params

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
        expect(assigns(:pre_auth)).to be_valid
      end
    end

    shared_examples "redirects to basic login self-registration" do
      it "with completion_redirect_path param" do
        get :new, params: authorize_params

        expect(response).to have_http_status(:redirect)

        actual_location = URI.parse(response.location)
        expected_location = URI.parse(
          group_self_registration_url(
            group_id: Group::AboBasicLogin.first!.id,
            completion_redirect_path: oauth_authorization_path(**authorize_params)
          )
        )

        expect(actual_location).to eq expected_location
      end
    end

    context "without any roles" do
      before { Role.delete_all }

      it_behaves_like "redirects to basic login self-registration" do
        it "strips out login prompt" do
          get :new, params: authorize_params.merge(prompt: :login)
          expect(response).to have_http_status(:redirect)

          actual_location = URI.parse(response.location)
          query = CGI.parse(CGI.parse(actual_location.query)["completion_redirect_path"][0])
          expect(query).not_to have_key("prompt")
        end
      end
    end

    context "with no active roles" do
      before { user.roles.update_all(end_on: 1.day.ago) }

      it_behaves_like "redirects to basic login self-registration" do
        it "strips out login prompt" do
          get :new, params: authorize_params.merge(prompt: :login)
          expect(response).to have_http_status(:redirect)

          actual_location = URI.parse(response.location)
          query = CGI.parse(CGI.parse(actual_location.query)["completion_redirect_path"][0])
          expect(query).not_to have_key("prompt")
        end
      end
    end
  end
end
