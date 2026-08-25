# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::Tabular::Events::Tours::Row do
  let(:tour) { events(:section_tour) }
  let(:row) { described_class.new(tour, nil, nil, nil) }

  def fetch(attr)
    row.fetch(attr)
  end

  it "translates the season to its human readable label" do
    expect(fetch(:season)).to eq "Sommer"
  end

  it "formats ascent and descent as one combined elevation value" do
    expect(fetch(:elevation)).to eq "2872 ↗ / 911 ↘"
  end

  it "returns an empty elevation when neither ascent nor descent are present" do
    tour.ascent = nil
    tour.descent = nil

    expect(fetch(:elevation)).to eq ""
  end

  it "joins the applicable prices with their label" do
    expect(fetch(:prices)).to eq(
      "Kosten SAC Sektionsmitglied: 50.0, Kosten SAC-Mitglied (extern): 60.0, " \
      "Kosten nicht-SAC-Mitglied (Gast): 80.0"
    )
  end

  it "formats the individual price columns without scientific notation" do
    expect(fetch(:price_special)).to eq "50.0"
    expect(fetch(:price_member)).to eq "60.0"
    expect(fetch(:price_regular)).to eq "80.0"
  end

  it "only includes leaders and assistant leaders, formatted with their role" do
    leader = Fabricate(Event::Role::Leader.sti_name.to_sym,
      participation: Fabricate(:event_participation, event: tour, participant: people(:admin)))
    assistant_leader = Fabricate(Event::Role::AssistantLeader.sti_name.to_sym,
      participation: Fabricate(:event_participation, event: tour, participant: people(:mitglied)))
    Fabricate(Event::Role::Helper.sti_name.to_sym,
      participation: Fabricate(:event_participation, event: tour, participant: people(:tourenchef)))

    expect(fetch(:leaders).split(", ")).to match_array([
      "#{people(:admin)} (#{leader.class.label})",
      "#{people(:mitglied)} (#{assistant_leader.class.label})"
    ])
  end

  it "only exports child activities, not the parent they belong to" do
    tour.activities << event_activities(:wandern)

    expect(fetch(:activities)).to eq event_activities(:wanderweg).label
  end

  it "only exports child technical requirements, not the parent they belong to" do
    tour.technical_requirements << event_technical_requirements(:wandern)

    expect(fetch(:technical_requirements)).to eq(
      [event_technical_requirements(:wandern_t3), event_technical_requirements(:wandern_t4)]
        .map(&:label).sort.join(", ")
    )
  end

  it "only exports child traits, not the parent they belong to" do
    tour.traits << event_traits(:travel)

    expect(fetch(:traits)).to eq(
      [event_traits(:public_transport), event_traits(:excursion)].map(&:label).sort.join(", ")
    )
  end

  it "exports all target groups without filtering by category" do
    expect(fetch(:target_groups)).to eq(
      [event_target_groups(:kinder), event_target_groups(:familien)].map(&:label).sort.join(", ")
    )
  end
end
