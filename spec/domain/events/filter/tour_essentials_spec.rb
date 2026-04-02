# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::Filter::TourEssentials do
  let(:section) { groups(:matterhorn) }
  let(:base_scope) { section.events.where(type: Event::Tour.sti_name) }

  let!(:hochtour) do
    Fabricate(:sac_tour,
      groups: [section],
      disciplines: event_disciplines(:felsklettern, :skihochtour),
      target_groups: event_target_groups(:senioren_b, :familien),
      fitness_requirement: event_fitness_requirements(:b))
  end

  let!(:wanderung) do
    Fabricate(:sac_tour,
      groups: [section],
      disciplines: [event_disciplines(:wanderweg)],
      target_groups: [event_target_groups(:senioren)],
      fitness_requirement: event_fitness_requirements(:d))
  end

  def filter_entries(params)
    described_class.new(:tour_essentials, params).apply(base_scope)
  end

  context "normalization" do
    it "removes empty args" do
      filter = described_class.new(
        :tour_essentials,
        discipline_id: "1",
        target_group_id: [""],
        trait_id: [1, ""],
        technical_requirement_id: ""
      )
      expect(filter.args).to eq(discipline_id: [1], trait_id: [1])
    end
  end

  context "with discipline filter" do
    it "includes only wander tour for sub discipline" do
      result = filter_entries(discipline_id: event_disciplines(:wanderweg).id)
      expect(result).to match_array([wanderung])
    end

    it "includes tour for main discipline" do
      result = filter_entries(discipline_id: event_disciplines(:wandern).id)
      expect(result).to match_array([wanderung])
    end

    it "includes tour for discipline and target group" do
      result = filter_entries(
        discipline_id: event_disciplines(:eisklettern, :felsklettern).map(&:id),
        target_group_id: event_target_groups(:senioren).id
      )
      expect(result).to match_array([hochtour])
    end
  end

  context "with target group filter" do
    it "includes only hochtour tour for sub target group" do
      result = filter_entries(target_group_id: event_target_groups(:senioren_b).id)
      expect(result).to match_array([hochtour])
    end

    it "includes all tours for main target group" do
      result = filter_entries(target_group_id: event_target_groups(:senioren).id)
      expect(result).to match_array([wanderung, hochtour])
    end
  end

  context "with fitness requirement filter" do
    it "includes only hochtour tour for single requirement" do
      result = filter_entries(fitness_requirement_id: event_fitness_requirements(:b).id)
      expect(result).to match_array([hochtour])
    end

    it "includes all tours for multiple requirements" do
      result = filter_entries(fitness_requirement_id: event_fitness_requirements(:b, :c, :d).map(&:id))
      expect(result).to match_array([wanderung, hochtour])
    end
  end
end
