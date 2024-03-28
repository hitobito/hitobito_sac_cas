# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

RSpec.describe "groups#show", type: :request do
  it_behaves_like 'jsonapi authorized requests' do
    let(:token) { service_tokens(:permitted_root_layer_token).token }
    let(:params) { {} }
    let(:group) { groups(:root) }

    subject(:make_request) do
      jsonapi_get "/api/groups/#{group.id}", params: params
    end

    describe 'basic fetch' do
      it 'works' do
        expect(GroupResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq('groups')
        expect(d.id).to eq(group.id)
      end
    end

    describe 'extra attribute section_self_registration_url' do
      let(:group) { groups(:bluemlisalp) }
      let(:params) { { extra_fields: { groups: 'membership_self_registration_url' } } }

      it 'includes the hostname' do
        expected_url = group.sac_cas_self_registration_url('www.example.com')
        expect(expected_url).to start_with('http://www.example.com/groups/')
        make_request
        expect(d.attributes['membership_self_registration_url']).to eq expected_url
      end
    end
  end
end
