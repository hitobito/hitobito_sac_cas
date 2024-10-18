# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "event_levels#index", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let!(:token) { service_tokens(:permitted_root_layer_token).token }
    let(:params) { {} }

    subject(:make_request) { jsonapi_get "/api/events", params: }

    context "with level_id filter" do
      let(:level) { Fabricate(:event_level) }
      let(:kind) { event_kinds(:slk) }

      before do
        kind.update!(level:)
        Event.first.update!(kind:)
      end

      it "only fetches events with specified kind_category_id" do
        expect(EventResource).to receive(:all).and_call_original
        jsonapi_get "/api/events", params: params.merge(filter: {level_id: level.id})
        expect(response.status).to eq(200), response.body
        expect(d.map(&:id)).to match_array([Event.first.id])
      end

      it "only fetches events without specified kind_category_id" do
        expect(EventResource).to receive(:all).and_call_original
        jsonapi_get "/api/events", params: params.merge(filter: {level_id: {not_eq: level.id}})
        expect(response.status).to eq(200), response.body
        expect(d.map(&:id)).not_to include(Event.first.id)
        expect(d.map(&:id)).not_to be_empty
      end
    end
  end
end
