# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Role do
  describe "cached leaders" do
    let(:tour) { events(:section_tour) }
    let(:participation) { Fabricate(:event_participation, event: tour, participant: people(:mitglied)) }

    def cached_leaders
      Event::CachedLeader.where(event_id: tour.id).pluck(:person_id, :role_type)
    end

    it "caches leader on create" do
      Event::Role::Leader.create!(participation:)

      expect(cached_leaders).to eq [[people(:mitglied).id, "Event::Role::Leader"]]
    end

    it "updates cache when type changes" do
      role = Event::Role::Leader.create!(participation:)

      role.update!(type: Event::Role::AssistantLeader.sti_name)

      expect(cached_leaders).to eq [[people(:mitglied).id, "Event::Role::AssistantLeader"]]
    end

    it "removes cached leader when destroying last role of participation" do
      role = Event::Role::Leader.create!(participation:)

      expect { role.reload.destroy! }.to change { cached_leaders.size }.from(1).to(0)
      expect(Event::Participation.exists?(participation.id)).to be false
    end

    it "removes cached leader when destroying leader role of participation with other roles" do
      role = Event::Role::Leader.create!(participation:)
      Event::Role::Helper.create!(participation:)

      expect { role.reload.destroy! }.to change { cached_leaders.size }.from(1).to(0)
    end

    it "removes cached leader when destroying participation" do
      Event::Role::Leader.create!(participation:)

      expect { participation.reload.destroy! }.to change { cached_leaders.size }.from(1).to(0)
    end
  end
end
