# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::RoleAbility do
  subject(:ability) { Ability.new(role.person.reload) }

  context "any" do
    let(:person) { people(:tourenchef) }

    context "on course" do
      let(:top_course) { events(:top_course) }
      let(:participation) {
        Event::Participation.create!(event: top_course, person: person, application_id: -1)
      }

      context "as leader" do
        let(:role) { Fabricate("Event::Course::Role::Leader", participation: participation) }

        [:show, :create, :update, :destroy].each do |action|
          it "may not #{action}" do
            expect(subject).not_to be_able_to(action, role)
          end
        end
      end

      context "as assistant leader" do
        let(:role) {
          Fabricate("Event::Course::Role::AssistantLeader", participation: participation)
        }

        [:show, :create, :update, :destroy].each do |action|
          it "may not #{action}" do
            expect(subject).not_to be_able_to(action, role)
          end
        end
      end
    end
  end

  context "as tour leader" do
    let(:tour) { events(:section_tour) }
    let(:leader) { Fabricate(:person) }
    let!(:own_role) do
      Fabricate(Event::Role::Leader.sti_name,
        participation: Event::Participation.create!(event: tour, person: leader))
    end

    subject(:ability) { Ability.new(leader.reload) }

    it "may destroy other leader role" do
      other_role = Fabricate(Event::Role::AssistantLeader.sti_name,
        participation: Event::Participation.create!(event: tour, person: Fabricate(:person)))

      expect(ability).to be_able_to(:destroy, other_role)
    end

    it "may destroy own leader role" do
      expect(ability).to be_able_to(:destroy, own_role)
    end
  end

  context "layer_created_events_full" do
    let(:tourenleiter) do
      Fabricate(Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation.sti_name,
        group: groups(:bluemlisalp_touren_und_kurse)).person
    end
    let(:tour) { events(:section_tour) }
    let(:participation) { Event::Participation.create!(event: tour, person: Fabricate(:person)) }

    subject(:ability) { Ability.new(tourenleiter.reload) }

    def build_role(type)
      participation.roles.build(type: type.sti_name).tap { |r| r.participation = participation }
    end

    context "on own tour" do
      before { tour.update_columns(creator_id: tourenleiter.id) }

      [Event::Role::Leader, Event::Role::AssistantLeader, Event::Role::Helper].each do |type|
        [:show, :create, :update, :destroy].each do |action|
          it "may #{action} #{type}" do
            expect(ability).to be_able_to(action, build_role(type))
          end
        end
      end

      it "may add roles" do
        expect(ability).to be_able_to(:new, tour.decorate.new_role)
      end

      it "may destroy own leader role" do
        own_participation = Event::Participation.create!(event: tour, person: tourenleiter)
        own_role = Fabricate(Event::Role::Leader.sti_name, participation: own_participation)

        expect(ability).to be_able_to(:destroy, own_role)
      end

      it "may not create participant role" do
        expect(ability).not_to be_able_to(:create, build_role(Event::Tour::Role::Participant))
      end
    end

    it "may not create leader on tour of someone else" do
      tour.update_columns(creator_id: Fabricate(:person).id)

      expect(ability).not_to be_able_to(:create, build_role(Event::Role::Leader))
    end

    it "may not create leader on own tour in other section" do
      tour.update_columns(creator_id: tourenleiter.id)
      tour.groups = [groups(:matterhorn)]

      expect(ability).not_to be_able_to(:create, build_role(Event::Role::Leader))
    end
  end
end
