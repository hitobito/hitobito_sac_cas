# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "OauthWorkflow" do
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:password) { "cNb@X7fTdiU4sWCMNos3gJmQV_d9e9" }

  before do
    @app = Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri)
  end

  describe "redirection after oauth sign in" do
    def extract_query(uri) = Rack::Utils.parse_query(URI.parse(uri).query)

    context "person with roles" do
      let(:user) { people(:mitglied) }

      it "redirects to oauth authorization path without prompt" do
        user.update!(password: password)
        oauth_params = {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, response_type: :code, scope: :openid, prompt: :login}
        get oauth_authorization_path(locale: nil), params: oauth_params

        post person_session_path, params: {person: {login_identity: user.email, password: password}}

        redirect_uri = URI.parse(response.headers["Location"])
        expect(redirect_uri.path).to eq "/oauth/authorize"
        # rubocop:todo Layout/LineLength
        expect(extract_query(redirect_uri)).to eq oauth_params.except(:prompt).stringify_keys.transform_values(&:to_s)
        # rubocop:enable Layout/LineLength
      end
    end

    context "roleless person" do
      let(:user) { people(:roleless) }

      # rubocop:todo Layout/LineLength
      it "redirects to wizard for roleless person which redirects to auth authorization path without prompt" do
        # rubocop:enable Layout/LineLength
        user.update!(password: password)
        oauth_params = {client_id: @app.uid, client_secret: @app.secret, redirect_uri: redirect_uri, response_type: :code, scope: :openid, prompt: :login}
        get oauth_authorization_path(locale: nil), params: oauth_params

        post person_session_path, params: {person: {login_identity: user.email, password: password}}

        redirect_uri = URI.parse(response.headers["Location"])
        # rubocop:todo Layout/LineLength
        expect(redirect_uri.path).to eq group_self_registration_path(group_id: Group::AboBasicLogin.first.id)
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        completion_path_params = extract_query(extract_query(redirect_uri)["completion_redirect_path"]).symbolize_keys
        # rubocop:enable Layout/LineLength
        expect(completion_path_params).to eq oauth_params.except(:prompt).transform_values(&:to_s)

        get redirect_uri.to_s
        completion_redirect_path = URI.parse(Capybara::Node::Simple.new(response.body).find(
          "#completion_redirect_path", visible: false
        )["value"]).to_s
        # rubocop:todo Layout/LineLength
        expect(completion_redirect_path).to eq oauth_authorization_path(completion_path_params.merge(locale: nil))
        # rubocop:enable Layout/LineLength

        post group_self_registration_path(group_id: Group::AboBasicLogin.first.id), params: {
          completion_redirect_path: completion_redirect_path,
          wizards_signup_abo_basic_login_wizard: {
            person_fields: {
              first_name: "Max",
              last_name: "Muster",
              address_care_of: "c/o Musterleute",
              birthday: "1.1.2000",
              data_protection: "1",
              street: "Musterplatz",
              housenumber: "42",
              postbox: "Postfach 23",
              town: "Zurich",
              zip_code: "8000",
              country: "CH"
            }
          }
        }
        redirect_uri = URI.parse(response.headers["Location"])
        expect(redirect_uri.request_uri).to eq completion_redirect_path
      end
    end
  end
end
