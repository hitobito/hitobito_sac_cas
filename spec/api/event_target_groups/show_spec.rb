# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "event_target_groups#show", type: :request do
  it_behaves_like "jsonapi authorized requests", person: nil, required_scopes: [:events] do
    let!(:service_token) { service_tokens(:permitted_root_layer_token) }
    let!(:target_group) { event_target_groups(:erwachsene) }
    let(:params) { {} }

    subject(:make_request) { jsonapi_get "/api/event_target_groups/#{target_group.id}", params: }

    describe "basic fetch" do
      it "works" do
        expect(Event::TargetGroupResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.jsonapi_type).to eq("event_target_groups")
        expect(d.id).to eq(target_group.id)
      end
    end
  end
end
