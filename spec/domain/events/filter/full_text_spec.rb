# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::Filter::FullText do
  let(:section) { groups(:matterhorn) }
  let(:base_scope) { section.events.where(type: Event::Tour.sti_name) }

  # child of :senioren, with a label that does not contain the parent's label
  let(:senioren_ue70) do
    Fabricate(:event_target_group, parent: event_target_groups(:senioren), label: "Ü70")
  end

  let!(:fels) do
    Fabricate(:sac_tour,
      groups: [section],
      activities: [event_activities(:felsklettern)], # label "Fels", parent label "Klettern"
      target_groups: [event_target_groups(:senioren_b)], # label "Senioren B"
      traits: [event_traits(:guided)], # label "Mit Bergführer", parent label "Organisation & Durchführung"
      fitness_requirement: event_fitness_requirements(:b), # short_label "B", label "B - wenig anstrengend"
      additional_info: "Verpflegung aus dem Rucksack")
  end

  let!(:wanderung) do
    Fabricate(:sac_tour,
      groups: [section],
      activities: [event_activities(:wanderweg)], # label "Wanderweg", parent label "Wandern"
      target_groups: [senioren_ue70],
      technical_requirements: [event_technical_requirements(:wandern_t3)], # label "T3", parent label "Wanderskala"
      fitness_requirement: event_fitness_requirements(:d)) # short_label "D", label "D - anstrengend"
  end

  def filter_entries(query)
    described_class.new(:full_text, q: query).apply(base_scope).distinct
  end

  def add_leader(event, last_name, first_name: nil, role_type: Event::Role::Leader, state: "assigned")
    participation = Fabricate(:event_participation,
      event: event,
      state: state,
      participant: Fabricate(:person, {last_name:, first_name:}.compact))
    Fabricate(role_type.sti_name.to_sym, participation: participation)
    # creating a role activates the participation
    participation.reload.update!(state: state)
    participation
  end

  context "activation" do
    it "is blank without query" do
      expect(described_class.new(:full_text, q: "  ")).to be_blank
    end

    it "is not blank for a word shorter than the minimum query length" do
      expect(described_class.new(:full_text, q: "b")).not_to be_blank
    end
  end

  context "with event_translations.additional_info" do
    it "includes only events with matching additional info" do
      expect(filter_entries("Rucksack")).to match_array([fels])
    end
  end

  context "with target group label" do
    it "includes events with matching target group label" do
      expect(filter_entries("Senioren B")).to match_array([fels])
    end

    it "excludes events matching only the parent target group label" do
      expect(filter_entries("Senioren")).to match_array([fels])
    end
  end

  context "with activity label" do
    it "includes events with matching activity label" do
      expect(filter_entries("Fels")).to match_array([fels])
    end

    it "includes events matching the parent activity label" do
      expect(filter_entries("Klettern")).to match_array([fels])
    end
  end

  context "with trait label" do
    it "includes events with matching trait label" do
      expect(filter_entries("Bergführer")).to match_array([fels])
    end

    it "excludes events matching only the parent trait label" do
      expect(filter_entries("Organisation")).to be_empty
    end
  end

  context "with fitness requirement label" do
    it "includes events with matching fitness requirement label" do
      expect(filter_entries("wenig")).to match_array([fels])
      expect(filter_entries("anstrengend")).to match_array([fels, wanderung])
    end
  end

  context "with leaders first_name" do
    it "includes events with matching leader" do
      add_leader(fels, "Hämmerli", first_name: "Ueli")
      expect(filter_entries("Ueli")).to match_array([fels])
    end
  end

  context "with leaders last_name" do
    it "includes events with matching leader" do
      add_leader(fels, "Hämmerli")
      expect(filter_entries("Hämmerli")).to match_array([fels])
    end

    it "includes events with matching assistant leader" do
      add_leader(fels, "Hämmerli", role_type: Event::Role::AssistantLeader)
      expect(filter_entries("Hämmerli")).to match_array([fels])
    end

    it "excludes events where the person has a non leader role" do
      add_leader(fels, "Hämmerli", role_type: Event::Role::Helper)
      expect(filter_entries("Hämmerli")).to be_empty
    end

    it "excludes events with inactive leader participation" do
      add_leader(fels, "Hämmerli", state: "canceled")
      expect(filter_entries("Hämmerli")).to be_empty
    end
  end

  context "with multiple words" do
    before do
      add_leader(fels, "Hämmerli")
      add_leader(fels, "Zürcher")
    end

    it "includes events where the words match different lists" do
      expect(filter_entries("Fels Hämmerli")).to match_array([fels])
    end

    it "includes events where the words match a list and the event itself" do
      expect(filter_entries("Hämmerli Rucksack")).to match_array([fels])
    end

    it "excludes events where the words match only different entries of the same list" do
      expect(filter_entries("Hämmerli Zürcher")).to be_empty
    end
  end

  context "with technical requirement label" do
    it "includes only events with equal label" do
      expect(filter_entries("t3")).to match_array([wanderung])
      expect(filter_entries("t2")).to be_empty
    end

    it "includes events matching the parent label" do
      expect(filter_entries("Wanderskala")).to match_array([wanderung])
    end

    it "combines with full text search" do
      expect(filter_entries("T3 Wanderweg")).to match_array([wanderung])
      expect(filter_entries("T3 Rucksack")).to be_empty
    end
  end

  context "with fitness requirement short_label" do
    it "includes only events with equal short label" do
      expect(filter_entries("b")).to match_array([fels])
      expect(filter_entries("d")).to match_array([wanderung])
    end

    it "ignores case" do
      expect(filter_entries("B")).to match_array([fels])
    end

    it "does not match partially" do
      expect(filter_entries("bb")).to be_empty
    end

    it "combines multiple short words with AND" do
      expect(filter_entries("b d")).to be_empty
    end

    it "combines with full text search" do
      expect(filter_entries("b Rucksack")).to match_array([fels])
      expect(filter_entries("d Rucksack")).to be_empty
      expect(filter_entries("b Wanderweg")).to be_empty
    end
  end
end
