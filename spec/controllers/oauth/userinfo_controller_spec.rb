# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Doorkeeper::OpenidConnect::UserinfoController do
  let(:user) { people(:admin) }
  let(:app) { Oauth::Application.create!(name: 'MyApp', redirect_uri: redirect_uri) }
  let(:redirect_uri) { 'urn:ietf:wg:oauth:2.0:oob' }
  let(:data) { JSON.parse(response.body) }

  describe 'GET#show' do
    context 'with name scope' do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
                                  scopes: 'openid name', expires_in: 2.hours)
      end

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200
        expect(data).to match({
          sub: user.id.to_s,
          first_name: user.first_name,
          last_name: user.last_name,
          nickname: user.nickname,
          address: user.address,
          zip_code: user.zip_code,
          town: user.town,
          country: user.country,
          phone_number: nil,
          picture_url: /\/packs-test\/media\/images\/profile-.*\.svg/,
        }.deep_stringify_keys)
      end
    end

    context 'with with_roles scope' do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
                                  scopes: 'openid with_roles', expires_in: 2.hours)
      end

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
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
          zip_code: user.zip_code,
          town: user.town,
          country: user.country,
          gender: user.gender,
          birthday: user.birthday.to_s.presence,
          primary_group_id: user.primary_group_id,
          language: user.language,
          phone_number: nil,
          membership_years: 0,
          picture_url: /\/packs-test\/media\/images\/profile-.*\.svg/,
          roles: [
            {
              group_id: user.roles.first.group_id,
              group_name: user.roles.first.group.name,
              role: 'Group::Geschaeftsstelle::Admin',
              role_class: 'Group::Geschaeftsstelle::Admin',
              role_name: 'Administration',
              permissions: ['layer_and_below_full', 'admin', 'impersonation', 'read_all_people'],
              layer_group_id: user.roles.first.group.layer_group_id
            }
          ]
        }.deep_stringify_keys)
      end

    end
    context 'with with_groups scope' do
      let(:token) do
        app.access_tokens.create!(resource_owner_id: user.id,
                                  scopes: 'openid with_groups', expires_in: 2.hours)
      end

      it 'has user_groups key' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200
        expect(data['user_groups']).to include 'SAC_employee'
      end
    end
  end
end
