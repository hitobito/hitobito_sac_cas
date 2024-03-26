# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe 'GET oauth/profile', type: :request do
  let(:application) { Fabricate(:application) }
  let(:user)        { people(:mitglied) }

  context 'with all scopes in token' do
    let(:token)  { Fabricate(:access_token, application: application, scopes: 'email name with_roles', resource_owner_id: user.id ) }

    context 'with scope "name" in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'name' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        json = JSON.parse(response.body)
        expect(json).to match({
                                id: user.id,
                                email: user.email,
                                first_name: user.first_name,
                                last_name: user.last_name,
                                nickname: user.nickname,
                                address: user.address,
                                zip_code: user.zip_code,
                                town: user.town,
                                country: user.country,
                                picture_url: /\/packs-test\/media\/images\/profil-.*\.png/,
                              }.deep_stringify_keys)
      end
    end

    context 'with scope "with_roles" in request' do
      it 'succeeds' do
        get '/oauth/profile', headers: { 'Authorization': 'Bearer ' + token.token, 'X-Scope': 'with_roles' }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        json = JSON.parse(response.body)
        expect(json).to match({
                             id: user.id,
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
                             picture_url: /\/packs-test\/media\/images\/profil-.*\.png/,
                             roles: [{
                               group_id: user.roles.first.group_id,
                               group_name: user.roles.first.group.name,
                               role: 'Group::SektionsMitglieder::Mitglied',
                               role_class: 'Group::SektionsMitglieder::Mitglied',
                               role_name: 'Mitglied (Stammsektion)',
                               permissions: [],
                               layer_group_id: user.roles.first.group.layer_group_id
                             },{
                               group_id: user.roles.second.group_id,
                               group_name: user.roles.second.group.name,
                               role: 'Group::SektionsMitglieder::MitgliedZusatzsektion',
                               role_class: 'Group::SektionsMitglieder::MitgliedZusatzsektion',
                               role_name: 'Mitglied (Zusatzsektion)',
                               permissions: [],
                               layer_group_id: user.roles.second.group.layer_group_id
                             }]
                           }.deep_stringify_keys)
      end
    end
  end
end
