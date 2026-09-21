# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::CachedLeader do
  let(:tour) { events(:section_tour) }
  let(:course) { events(:top_course) }

  def add_role(event, person, role_type)
    participation = Fabricate(:event_participation, event: event, participant: person)
    role_type.create!(participation: participation)
    participation
  end

  def cached_for(event)
    described_class.where(event_id: event.id).pluck(:person_id, :role_type)
  end

  describe ".backfill_event" do
    it "caches one row per active leader participation" do
      add_role(tour, people(:mitglied), Event::Role::Leader)
      described_class.delete_all

      described_class.backfill_event(tour)

      expect(cached_for(tour)).to eq [[people(:mitglied).id, "Event::Role::Leader"]]
    end

    it "omits roles whose kind is not :leader" do
      add_role(tour, people(:familienmitglied), Event::Tour::Role::Participant)
      add_role(tour, people(:familienmitglied2), Event::Role::Helper)
      described_class.delete_all

      described_class.backfill_event(tour)

      expect(cached_for(tour)).to be_empty
    end

    it "omits inactive participations" do
      # The role activates its participation, hence the update_column
      add_role(tour, people(:mitglied), Event::Role::Leader).update_column(:active, false)
      described_class.delete_all

      described_class.backfill_event(tour)

      expect(cached_for(tour)).to be_empty
    end

    it "picks up the event type's own leader roles" do
      add_role(course, people(:admin), Event::Course::Role::LeaderAspirant)
      described_class.delete_all

      described_class.backfill_event(course)

      expect(cached_for(course))
        .to eq [[people(:admin).id, "Event::Course::Role::LeaderAspirant"]]
    end

    it "drops cached rows that no longer have a leader role" do
      described_class.create!(event: tour, person: people(:mitglied),
        role_type: "Event::Role::Leader")

      described_class.backfill_event(tour)

      expect(cached_for(tour)).to be_empty
    end

    it "leaves the cache of other events untouched" do
      add_role(course, people(:admin), Event::Course::Role::Leader)

      expect { described_class.backfill_event(tour) }.not_to change { cached_for(course) }
    end
  end

  describe ".backfill_all" do
    it "caches the leaders of every event type" do
      add_role(tour, people(:mitglied), Event::Role::Leader)
      add_role(course, people(:admin), Event::Course::Role::Leader)
      described_class.delete_all

      described_class.backfill_all

      expect(cached_for(tour)).to eq [[people(:mitglied).id, "Event::Role::Leader"]]
      expect(cached_for(course)).to eq [[people(:admin).id, "Event::Course::Role::Leader"]]
    end
  end
end
