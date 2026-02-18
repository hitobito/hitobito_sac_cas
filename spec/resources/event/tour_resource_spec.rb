# frozen_string_literal: true

#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe Event::TourResource, type: :resource do
  let(:event) { events(:section_tour) }
  let(:person) { people(:admin) }

  it "includes attributes" do
    render
    data = jsonapi_data[0]
    expect(data["name"]).to eq("Bundstock")
    expect(data["state"]).to eq("review")
  end

  it "includes leaders" do
    leader = people(:tourenchef)
    participation = event.participations.create!(person: leader, active: true)
    Event::Role::Leader.create!(participation: participation)

    params[:include] = "leaders"
    render
    data = jsonapi_data[0]
    leaders = data.sideload(:leaders)
    expect(leaders.size).to eq(1)
    expect(leaders.first.id).to eq(leader.id)
    expect(leaders.first.first_name).to eq(leader.first_name)
    expect(leaders.first.last_name).to eq(leader.last_name)
  end
end
