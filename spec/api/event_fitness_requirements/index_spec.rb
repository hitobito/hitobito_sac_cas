# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe "event_fitness_requirements#index", type: :request do
  it_behaves_like "jsonapi authorized requests", person: nil, required_scopes: [:events] do
    let!(:service_token) { service_tokens(:permitted_root_layer_token) }
    let!(:fitness_requirements) { Fabricate.times(3, :event_fitness_requirement) + event_fitness_requirements }
    let(:params) { {page: {size: 100}} }

    subject(:make_request) { jsonapi_get "/api/event_fitness_requirements", params: }

    describe "basic fetch" do
      it "works" do
        expect(Event::FitnessRequirementResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["event_fitness_requirements"])
        expect(d.map(&:id)).to match_array(fitness_requirements.pluck(:id))
      end
    end
  end
end
