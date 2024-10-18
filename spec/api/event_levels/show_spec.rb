# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "event_levels#show", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let!(:token) { service_tokens(:permitted_root_layer_token).token }
    let!(:level) { Fabricate(:event_level) }
    let(:params) { {} }

    subject(:make_request) { jsonapi_get "/api/event_levels/#{level.id}", params: }

    describe "basic fetch" do
      it "works" do
        expect(Event::LevelResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.jsonapi_type).to eq("event_levels")
        expect(d.id).to eq(level.id)
      end
    end
  end
end
