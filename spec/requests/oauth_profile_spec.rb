# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "GET oauth/profile", type: :request do
  let(:application) { Fabricate(:application) }
  let(:user) { people(:mitglied) }
  let(:json) { JSON.parse(response.body) }
  let(:token) do
    Fabricate(:access_token, application: application, scopes: "name #{scope}",
      resource_owner_id: user.id)
  end

  def make_request(skip_checks: true)
    get "/oauth/profile", headers: {Authorization: "Bearer " + token.token, "X-Scope": scope}
    return if skip_checks

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq("application/json; charset=utf-8")
  end

  context 'with scope "name" in request' do
    let(:scope) { :name }

    it "succeeds" do
      make_request
      expect(json).to match({
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        nickname: user.nickname,
        address: user.address,
        address_care_of: user.address_care_of,
        street: user.street,
        postbox: user.postbox,
        housenumber: user.housenumber,
        zip_code: user.zip_code,
        town: user.town,
        country: user.country,
        picture_url: /\/packs(-test)?\/media\/images\/profile-.*\.svg/,
        phone: nil
      }.deep_stringify_keys)
    end
  end

  context 'with scope "with_roles" in request' do
    let(:scope) { "with_roles" }

    it "succeeds" do
      make_request
      expect(json).to match({
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        nickname: user.nickname,
        company_name: user.company_name,
        company: user.company,
        email: user.email,
        address: user.address,
        address_care_of: user.address_care_of,
        street: user.street,
        postbox: user.postbox,
        housenumber: user.housenumber,
        zip_code: user.zip_code,
        town: user.town,
        country: user.country,
        gender: user.gender,
        birthday: user.birthday.to_s.presence,
        primary_group_id: user.primary_group_id,
        language: user.language,
        picture_url: %r{packs(-test)?/media/images/profile-.*\.svg},
        phone: nil,
        membership_years: "1.0",
        roles: [{
          group_id: user.roles.first.group_id,
          group_name: user.roles.first.group.name,
          role: "Group::SektionsMitglieder::Mitglied",
          role_class: "Group::SektionsMitglieder::Mitglied",
          role_name: "Mitglied (Stammsektion)",
          permissions: [],
          layer_group_id: user.roles.first.group.layer_group_id
        }, {
          group_id: user.roles.second.group_id,
          group_name: user.roles.second.group.name,
          role: "Group::SektionsMitglieder::MitgliedZusatzsektion",
          role_class: "Group::SektionsMitglieder::MitgliedZusatzsektion",
          role_name: "Mitglied (Zusatzsektion)",
          permissions: [],
          layer_group_id: user.roles.second.group.layer_group_id
        }]
      }.deep_stringify_keys)
    end
  end

  context 'with scope "user_groups" in request' do
    let(:scope) { "user_groups" }

    it "succeeds" do
      make_request
      expect(json["user_groups"]).to include "SAC_member"
    end

    it "is forbidden to be used without names scope on token" do
      token.update!(scopes: "user_groups")
      make_request
      expect(response).to have_http_status(:forbidden)
    end
  end
end
