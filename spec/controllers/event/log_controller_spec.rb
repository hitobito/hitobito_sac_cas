# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::LogController, versioning: true do
  render_views

  let(:tour) { events(:section_tour) }

  before do
    sign_in(people(:admin))
    tour.update_column(:state, :draft)
  end

  it "renders added tour essentials" do
    tour.activities << event_activities(:wandern)
    tour.target_groups << event_target_groups(:senioren)
    tour.technical_requirements << event_technical_requirements(:singletrail)
    tour.traits << event_traits(:training)

    get :index, params: {group_id: tour.groups.first.id, id: tour.id}

    expect(response).to be_ok
    expect(assigns(:versions).size).to eq(4)
  end
end
