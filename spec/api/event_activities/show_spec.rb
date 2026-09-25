# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "event_activities#show", type: :request do
  it_behaves_like "jsonapi authorized requests", person: nil, required_scopes: [:events] do
    let!(:service_token) { service_tokens(:permitted_root_layer_token) }
    let!(:activity) { event_activities(:wandern) }
    let(:params) { {} }

    subject(:make_request) { jsonapi_get "/api/event_activities/#{activity.id}", params: }

    describe "basic fetch" do
      it "works" do
        expect(Event::ActivityResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.jsonapi_type).to eq("event_activities")
        expect(d.id).to eq(activity.id)
        expect(d.label).to eq(activity.label)
      end

      context "with extra icon" do
        let(:params) { {extra_fields: {event_activities: :icon}} }

        it "works" do
          activity.icon.attach(
            io: Rails.root.join("spec", "fixtures", "person", "test_picture.jpg").open,
            filename: "test_picture.jpg"
          )
          make_request
          expect(response.status).to eq(200), response.body
          expect(d.icon).to match(/active_storage\/blobs\/.+\/test_picture.jpg/)
        end
      end
    end
  end
end
