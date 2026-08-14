# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Filter::MyAssistantLeader do
  let(:person) { Fabricate(:person) }

  subject(:filter) { described_class.new(:my_main_leader, {}) }

  context "filter activation" do
    it "is blank when there is no current person" do
      allow(Auth).to receive(:current_person).and_return(nil)
      expect(filter).to be_blank
    end

    it "is not blank when there is a current person" do
      allow(Auth).to receive(:current_person).and_return(person)
      expect(filter).not_to be_blank
    end
  end

  context "filter role_types" do
    let(:event) { events(:top_event) }
    let(:base_scope) { Event.all }

    def add_role(role_class)
      participation = Fabricate(:event_participation, event:, participant: person)
      Fabricate(role_class.name.to_sym, participation: participation)
    end

    def filtered
      filter.apply(base_scope)
    end

    before do
      allow(Auth).to receive(:current_person).and_return(person)
    end

    it "excludes if person is main leader" do
      add_role(Event::Role::Leader)
      expect(filtered).not_to include(event)
    end

    it "includes if person is assistant leader" do
      add_role(Event::Role::AssistantLeader)
      expect(filtered).to include(event)
    end

    it "includes if person is helper" do
      add_role(Event::Role::Helper)
      expect(filtered).to include(event)
    end

    it "includes if person is cook" do
      add_role(Event::Role::Cook)
      expect(filtered).to include(event)
    end

    it "excludes if person is participant" do
      add_role(Event::Role::Participant)
      expect(filtered).not_to include(event)
    end

    it "excludes if person has no role" do
      expect(filtered).not_to include(event)
    end

    describe "course" do
      let(:base_scope) { Event::Course }
      let(:event) { events(:top_course) }

      it "excludes if person is main leader" do
        add_role(Event::Course::Role::Leader)
        expect(filtered).not_to include(event)
      end

      it "includes if person is assistant leader" do
        add_role(Event::Course::Role::AssistantLeader)
        expect(filtered).to include(event)
      end

      it "includes if person is assistant leader aspirant" do
        add_role(Event::Course::Role::AssistantLeaderAspirant)
        expect(filtered).to include(event)
      end
    end
  end
end
