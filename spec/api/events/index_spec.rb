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

    context "with include leaders" do
      it "includes only leaders" do
        course = events(:top_course)
        leader = people(:tourenchef)
        participation = course.participations.create!(person: leader, active: true)
        Event::Course::Role::Leader.create!(participation: participation)
        assistant = event_participations(:top_familienmitglied)
        Event::Course::Role::AssistantLeader.create!(participation: assistant)

        jsonapi_get "/api/events", params: {include: "leaders"}

        expect(response.status).to eq(200), response.body

        expect(json["data"].first["id"]).to eq(course.id.to_s)
        expect(json["data"].first["relationships"]["leaders"]["data"].size).to eq(1)
        expect(json["data"].first["relationships"]["leaders"]["data"].first["id"]).to eq(leader.id.to_s)
        expect(json["included"].first["id"]).to eq(leader.id.to_s)
      end
    end

    context "caching" do
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        Rails.cache.clear
      end

      it "does not execute query again for same params" do
        expect(EventResource).to receive(:all).and_call_original.once
        2.times do
          jsonapi_get "/api/events"
          expect(response.status).to eq(200), response.body
          expect(json["data"]).to have(4).items
        end
      end

      it "does execute query twice if params differ" do
        expect(EventResource).to receive(:all).and_call_original.twice
        jsonapi_get "/api/events"
        jsonapi_get "/api/events", params: {page: {size: 2}}
      end

      it "does execute query again if Event updated_at changes" do
        expect(EventResource).to receive(:all).and_call_original.twice
        jsonapi_get "/api/events"
        travel_to(1.minute.from_now) do
          Event.last.touch
          jsonapi_get "/api/events"
        end
      end

      it "does execute query again if Event::Participation updated_at changes" do
        expect(EventResource).to receive(:all).and_call_original.twice
        jsonapi_get "/api/events"
        travel_to(1.minute.from_now) do
          Event::Participation.last.touch
          jsonapi_get "/api/events"
        end
        jsonapi_get "/api/events"
      end

      it "does execute query again if cache expired" do
        expect(EventResource).to receive(:all).and_call_original.twice
        jsonapi_get "/api/events"
        travel_to(3.hours.from_now + 1.minute) do
          jsonapi_get "/api/events"
        end
      end
    end
  end
end
