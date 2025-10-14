# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Doorkeeper::OpenidConnect::UserinfoController do
  let(:user) { people(:admin) }
  let(:app) { Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:data) { JSON.parse(response.body) }

  before do
    # rubocop:todo Layout/LineLength
    allow_any_instance_of(People::Membership::VerificationQrCode).to receive(:membership_verify_token).and_return("aSuperSweetToken42")
    # rubocop:enable Layout/LineLength
  end

  describe "GET#show" do
    context "with name scope" do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
          scopes: "openid name", expires_in: 2.hours)
      end

      it "shows the userinfo" do
        get :show, params: {access_token: token.token}
        expect(response.status).to eq 200
        expect(data).to match({
          sub: user.id.to_s,
          first_name: user.first_name,
          last_name: user.last_name,
          nickname: user.nickname,
          address: user.address,
          address_care_of: user.address_care_of,
          street: user.street,
          housenumber: user.housenumber,
          postbox: user.postbox,
          zip_code: user.zip_code,
          town: user.town,
          country: user.country,
          phone_number_landline: nil,
          phone_number_mobile: nil,
          picture_url: %r{packs(-test)?/media/images/profile-.*\.svg},
          membership_verify_url: nil
        }.deep_stringify_keys)
      end

      context "with membership" do
        let(:user) { mitglied.person }
        let(:mitglied) { roles(:mitglied) }

        it "includes membership_verify_url" do
          get :show, params: {access_token: token.token}
          expect(response.status).to eq 200
          expect(data["membership_verify_url"]).to eq "http://localhost:3000/verify_membership/aSuperSweetToken42"
        end

        it "includes membership_verify_url even if expired" do
          mitglied.update!(end_on: 1.year.ago)
          get :show, params: {access_token: token.token}
          expect(response.status).to eq 200
          expect(data["membership_verify_url"]).to eq "http://localhost:3000/verify_membership/aSuperSweetToken42"
        end
      end
    end

    context "with with_roles scope" do
      let(:root) { groups(:root) }
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
          scopes: "openid with_roles", expires_in: 2.hours)
      end

      it "shows the userinfo" do
        get :show, params: {access_token: token.token}
        expect(response.status).to eq 200
        expect(data).to match({
          sub: user.id.to_s,
          first_name: user.first_name,
          last_name: user.last_name,
          nickname: user.nickname,
          company_name: user.company_name,
          company: user.company,
          email: user.email,
          address: user.address,
          address_care_of: user.address_care_of,
          street: user.street,
          housenumber: user.housenumber,
          postbox: user.postbox,
          zip_code: user.zip_code,
          town: user.town,
          country: user.country,
          gender: user.gender,
          birthday: user.birthday.to_s.presence,
          primary_group_id: user.primary_group_id,
          language: user.language,
          phone_number_landline: nil,
          phone_number_mobile: nil,
          membership_years: 0,
          picture_url: %r{packs(-test)?/media/images/profile-.*\.svg},
          membership_verify_url: nil,
          roles: [
            {
              group_id: user.roles.first.group_id,
              group_name: user.roles.first.group.name,
              role: "Group::Geschaeftsstelle::Admin",
              role_class: "Group::Geschaeftsstelle::Admin",
              role_name: "Administration",
              permissions: %w[layer_and_below_full admin impersonation read_all_people],
              layer_group_id: root.id,
              layer_group_name: root.name
            }
          ]
        }.deep_stringify_keys)
      end
    end

    context "with user_groups scope" do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
          scopes: "openid user_groups", expires_in: 2.hours)
      end

      it "has user_groups key" do
        get :show, params: {access_token: token.token}
        expect(response.status).to eq 200
        expect(data["user_groups"]).to include "SAC_employee"
      end
    end
  end
end
