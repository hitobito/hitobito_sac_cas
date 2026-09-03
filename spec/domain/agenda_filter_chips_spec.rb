# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe AgendaFilterChips do
  include Rails.application.routes.url_helpers

  let(:group) { groups(:bluemlisalp) }
  let(:target_groups) { Event::TargetGroup.list.without_deleted.includes(:translations) }
  let(:activities) { Event::Activity.list.without_deleted.includes(:translations) }
  let(:technical_requirements) { Event::TechnicalRequirement.list.without_deleted.includes(:translations) }
  let(:fitness_requirements) { Event::FitnessRequirement.list.without_deleted.includes(:translations) }
  let(:traits) { Event::Trait.list.without_deleted.includes(:translations) }
  let(:leaders) { Person.limit(5) }

  def chips_for(filters)
    event_filter = Events::Filter::AgendaList.new(nil, filters: filters)
    described_class.new(event_filter, group,
      target_groups: target_groups,
      activities: activities,
      technical_requirements: technical_requirements,
      fitness_requirements: fitness_requirements,
      traits: traits,
      leaders: leaders).chips
  end

  it "is empty without any active filter" do
    expect(chips_for({})).to eq([])
  end

  it "ignores the default since date, which is applied even without user interaction" do
    expect(chips_for(date_range: {since: I18n.l(Time.zone.today)})).to eq([])
  end

  it "builds a chip for an active date range filter, dropping just that key on removal" do
    chips = chips_for(date_range: {until: "01.01.2027"})

    expect(chips.size).to eq(1)
    expect(chips.first[:label]).to eq("Bis: 01.01.2027")
    expect(chips.first[:path]).to eq(agenda_index_path(group_id: group.id, filters: {}))
  end

  it "builds a quoted chip for the full-text filter, clearing it on removal" do
    chips = chips_for(full_text: {q: "Bundstock"})

    expect(chips.size).to eq(1)
    expect(chips.first[:label]).to eq("\"Bundstock\"")
    expect(chips.first[:path]).to eq(agenda_index_path(group_id: group.id, filters: {}))
  end

  it "builds one chip per selected essential, each dropping only its own id on removal" do
    senioren = event_target_groups(:senioren)
    familien = event_target_groups(:familien)

    chips = chips_for(tour_essentials: {target_group_id: [senioren.id, familien.id]})

    expect(chips.pluck(:label)).to contain_exactly(senioren.label, familien.label)

    senioren_chip = chips.find { |c| c[:label] == senioren.label }
    expect(senioren_chip[:path]).to eq(
      agenda_index_path(group_id: group.id,
        filters: {tour_essentials: {target_group_id: [familien.id.to_s]}})
    )
  end

  it "skips an essential id that matches none of the given entries" do
    chips = chips_for(tour_essentials: {target_group_id: [-1]})

    expect(chips).to eq([])
  end
end
