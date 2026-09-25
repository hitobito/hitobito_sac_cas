# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "event_traits#show", type: :request do
  it_behaves_like "jsonapi authorized requests", person: nil, required_scopes: [:events] do
    let!(:service_token) { service_tokens(:permitted_root_layer_token) }
    let!(:trait) { event_traits(:public_transport) }
    let(:params) { {} }

    subject(:make_request) { jsonapi_get "/api/event_traits/#{trait.id}", params: }

    describe "basic fetch" do
      it "works" do
        expect(Event::TraitResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.jsonapi_type).to eq("event_traits")
        expect(d.id).to eq(trait.id)
      end
    end
  end
end
