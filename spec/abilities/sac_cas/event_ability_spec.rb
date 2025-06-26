# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe EventAbility do
  let(:person) { Fabricate(:person) }
  let(:participation) { Event::Participation.create!(person:, event: events(:top_course)) }

  subject(:ability) { Ability.new(person.reload) }

  describe "manage_attachments" do
    [Event::Course::Role::Leader, Event::Course::Role::AssistantLeader].each do |role|
      before { Fabricate(role.sti_name, participation:) }

      it "is able to manage_attachments as #{role}" do
        expect(ability).to be_able_to(:manage_attachments, events(:top_course))
      end
    end

    it "is not able to manage_attachments without leader role" do
      participation.roles.destroy_all
      expect(ability).not_to be_able_to(:manage_attachments, events(:top_course))
    end
  end

  describe "layer_events_full" do
    let(:touren_group) { groups(:bluemlisalp_touren_und_kurse) }

    before do
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation.create!(group: touren_group, person: person)
    end

    it "is able to create tours in section" do
      expect(ability).to be_able_to(:create, Event::Tour.new(groups: [groups(:bluemlisalp)]))
    end

    it "is not able to create events in group" do
      expect(ability).not_to be_able_to(:create, Event.new(groups: [touren_group]))
    end

    it "is not able to create tours in ortsgruppe" do
      expect(ability).not_to be_able_to(:create, Event::Tour.new(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)]))
    end

    it "is not able to create tours in other section" do
      expect(ability).not_to be_able_to(:create, Event::Tour.new(groups: [groups(:matterhorn)]))
    end
  end
end
