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

  before { allow(Graphiti.context[:object]).to receive(:current_scopes).and_return(["api"]) }

  it "includes attributes" do
    render
    data = jsonapi_data[0]
    expect(data["name"]).to eq("Bundstock")
    expect(data["state"]).to eq("review")
    expect(data["summit"]).to eq("Grosser Bundstock")
    expect(data["subito"]).to eq(false)
    expect(data["duration"]).to eq(750)
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

  describe "filtering" do
    # A second tour, assigned to none of the entries the filters below match on.
    let!(:other) { Fabricate(:sac_tour, groups: [groups(:bluemlisalp)]) }

    it "by activity_id returns only tours with that activity" do
      params[:filter] = {activity_id: event_activities(:wanderweg).id}
      render
      expect(jsonapi_data.map(&:id)).to eq([event.id])
    end

    it "by target_group_id returns only tours with that target group" do
      params[:filter] = {target_group_id: event_target_groups(:kinder).id}
      render
      expect(jsonapi_data.map(&:id)).to eq([event.id])
    end

    it "by technical_requirement_id returns only tours with that technical requirement" do
      params[:filter] = {technical_requirement_id: event_technical_requirements(:wandern_t3).id}
      render
      expect(jsonapi_data.map(&:id)).to eq([event.id])
    end

    it "by trait_id returns only tours with that trait" do
      params[:filter] = {trait_id: event_traits(:excursion).id}
      render
      expect(jsonapi_data.map(&:id)).to eq([event.id])
    end

    it "by fitness_requirement_id returns only tours with that fitness requirement" do
      params[:filter] = {fitness_requirement_id: event_fitness_requirements(:b).id}
      render
      expect(jsonapi_data.map(&:id)).to eq([event.id])
    end
  end
end
