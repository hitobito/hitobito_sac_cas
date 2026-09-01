# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe AgendaLeaders do
  let(:tour) { events(:section_tour) }
  let(:course) { events(:top_course) }

  def leaders_of(*events)
    described_class.new(events).to_h
  end

  def add_role(event, person, role_type)
    participation = Fabricate(:event_participation, event: event, participant: person)
    role_type.create!(participation: participation)
    participation
  end

  it "is an empty hash without any event" do
    expect(leaders_of).to eq({})
  end

  it "has an entry for every event, even without leaders" do
    expect(leaders_of(tour, course)).to eq(tour.id => [], course.id => [])
  end

  it "includes the leaders but not the participants nor the helpers" do
    add_role(tour, people(:mitglied), Event::Role::Leader)
    add_role(tour, people(:familienmitglied), Event::Tour::Role::Participant)
    add_role(tour, people(:familienmitglied2), Event::Role::Helper)

    expect(leaders_of(tour)[tour.id].map(&:to_s)).to eq ["Edmund Hillary"]
  end

  it "includes every role whose kind is :leader, not just Event::Role::Leader" do
    add_role(tour, people(:mitglied), Event::Role::AssistantLeader)

    expect(leaders_of(tour)[tour.id].map(&:to_s)).to eq ["Edmund Hillary"]
  end

  it "picks up the event type's own leader roles" do
    add_role(course, people(:admin), Event::Course::Role::LeaderAspirant)

    expect(leaders_of(course)[course.id].map(&:to_s)).to eq ["Anna Admin"]
  end

  it "omits inactive participations" do
    # The role activates its participation, hence the update_column
    add_role(tour, people(:mitglied), Event::Role::Leader).update_column(:active, false)

    expect(leaders_of(tour)[tour.id]).to be_empty
  end

  it "keys the leaders by event" do
    add_role(tour, people(:mitglied), Event::Role::Leader)
    add_role(course, people(:admin), Event::Course::Role::Leader)

    result = leaders_of(tour, course)

    expect(result[tour.id].map(&:to_s)).to eq ["Edmund Hillary"]
    expect(result[course.id].map(&:to_s)).to eq ["Anna Admin"]
  end

  it "orders by role type as configured in role_types, then by name" do
    add_role(tour, people(:familienmitglied2), Event::Role::AssistantLeader) # Frieda Norgay
    add_role(tour, people(:familienmitglied), Event::Role::AssistantLeader)  # Tenzing Norgay
    add_role(tour, people(:mitglied), Event::Role::Leader)                   # Edmund Hillary
    add_role(tour, people(:admin), Event::Role::Leader)                      # Anna Admin

    expect(leaders_of(tour)[tour.id].map(&:to_s))
      .to eq ["Anna Admin", "Edmund Hillary", "Frieda Norgay", "Tenzing Norgay"]
  end

  it "lists a person holding several leader roles once, under the first of them" do
    participation = add_role(tour, people(:mitglied), Event::Role::AssistantLeader)
    Event::Role::Leader.create!(participation: participation)
    add_role(tour, people(:admin), Event::Role::AssistantLeader)

    expect(leaders_of(tour)[tour.id].map(&:to_s)).to eq ["Edmund Hillary", "Anna Admin"]
  end

  it "loads the leaders of all events with a single query" do
    add_role(tour, people(:mitglied), Event::Role::Leader)
    add_role(course, people(:admin), Event::Course::Role::Leader)

    expect { leaders_of(tour, course) }.to make(1).db_query
  end
end
