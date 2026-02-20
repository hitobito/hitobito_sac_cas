# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
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

      it "may manage_attachments as #{role}" do
        expect(ability).to be_able_to(:manage_attachments, events(:top_course))
      end
    end

    it "may not manage_attachments without leader role" do
      participation.roles.destroy_all
      expect(ability).not_to be_able_to(:manage_attachments, events(:top_course))
    end
  end

  describe "layer_events_full" do
    let(:touren_group) { groups(:bluemlisalp_touren_und_kurse) }

    before do
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation.create!(group: touren_group,
        person: person)
    end

    it "may create tours in section" do
      expect(ability).to be_able_to(:create, Event::Tour.new(groups: [groups(:bluemlisalp)]))
    end

    it "may not create events in group" do
      expect(ability).not_to be_able_to(:create, Event.new(groups: [touren_group]))
    end

    it "may not create tours in ortsgruppe" do
      expect(ability).not_to be_able_to(:create,
        Event::Tour.new(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)]))
    end

    it "may not create tours in other section" do
      expect(ability).not_to be_able_to(:create, Event::Tour.new(groups: [groups(:matterhorn)]))
    end
  end

  describe "tourenchef_layer_events_manage" do
    let(:touren_group) { groups(:bluemlisalp_touren_und_kurse) }

    before do
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation.create!(group: touren_group,
        person: person)
    end

    [Event, Event::Course, Event::Tour].each do |event_class|
      describe event_class.sti_name do
        it "may create in section" do
          expect(ability).to be_able_to(:create, event_class.new(groups: [groups(:bluemlisalp)]))
        end

        it "may not create in group" do
          expect(ability).not_to be_able_to(:create, event_class.new(groups: [touren_group]))
        end

        it "may not create in ortsgruppe" do
          expect(ability).not_to be_able_to(:create,
            event_class.new(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)]))
        end

        it "may not create in other section" do
          expect(ability).not_to be_able_to(:create, event_class.new(groups: [groups(:matterhorn)]))
        end

        [:update, :assign_tags, :manage_attachments].each do |action|
          it "may #{action} if created by themselves" do
            expect(ability).to be_able_to(action, event_class.new(groups: [groups(:bluemlisalp)],
              creator: person))
          end

          it "may not #{action} if created by someone else" do
            expect(ability).not_to be_able_to(action, event_class.new(groups: [groups(:bluemlisalp)],
              creator: Fabricate(:person)))
          end
        end
      end
    end
  end

  describe Group::FreigabeKomitee::Pruefer do
    let(:tour) { events(:section_tour) }
    let!(:pruefer_role) { Group::FreigabeKomitee::Pruefer.create!(group: freigabe_komitee, person: person) }

    context "in sektion freigabe komitee" do
      let(:freigabe_komitee) { groups(:bluemlisalp_freigabekomitee) }

      it "may update matching tour" do
        expect(ability).to be_able_to(:update, tour)
      end

      it "may update tour if komitee covers only one of the responsibilities" do
        freigabe_komitee.event_approval_commission_responsiblities.destroy_all
        freigabe_komitee.event_approval_commission_responsiblities.create!(
          sektion: groups(:bluemlisalp),
          discipline: event_disciplines(:wandern),
          target_group: event_target_groups(:kinder),
          subito: true
        )

        expect(ability).to be_able_to(:update, tour)
      end

      it "may update matching tour from ortsgruppe in same sektion" do
        tour.update!(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)])

        expect(ability).to be_able_to(:update, tour)
      end

      it "may not update tour from another sektion" do
        tour.update!(groups: [groups(:matterhorn)])

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "may not update tour if komitee of pruefer role does not covers any of the responsibilities" do
        freigabe_komitee.event_approval_commission_responsiblities.destroy_all

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "may not update tour without pruefer role" do
        pruefer_role.destroy!

        expect(ability).not_to be_able_to(:update, tour)
      end
    end

    context "in ortsgruppe freigabe komitee" do
      let(:freigabe_komitee) { groups(:bluemlisalp_ortsgruppe_ausserberg_freigabe_komitee) }

      before do
        tour.update!(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)])
      end

      it "may update matching tour" do
        expect(ability).to be_able_to(:update, tour)
      end

      it "may not update matching tour from upper sektion" do
        tour.update!(groups: [groups(:bluemlisalp)])

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "may not update tour from an ortsgruppe in another sektion" do
        another_ortsgruppe = Fabricate(Group::Ortsgruppe.sti_name, parent: groups(:matterhorn), foundation_year: 2000)
        tour.update!(groups: [another_ortsgruppe])

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "may not update tour if komitee of pruefer role does not covers any of the responsibilities" do
        freigabe_komitee.event_approval_commission_responsiblities.destroy_all

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "may not update tour without pruefer role" do
        pruefer_role.destroy!

        expect(ability).not_to be_able_to(:update, tour)
      end
    end
  end
end
