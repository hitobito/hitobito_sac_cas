# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "event_traits#index", type: :request do
  it_behaves_like "jsonapi authorized requests", person: nil, required_scopes: [:events] do
    let!(:service_token) { service_tokens(:permitted_root_layer_token) }
    let!(:traits) { Fabricate.times(3, :event_trait) + event_traits }
    let(:params) { {page: {size: 100}} }

    subject(:make_request) { jsonapi_get "/api/event_traits", params: }

    describe "basic fetch" do
      it "works" do
        expect(Event::TraitResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["event_traits"])
        expect(d.map(&:id)).to match_array(traits.pluck(:id))
      end
    end
  end
end
