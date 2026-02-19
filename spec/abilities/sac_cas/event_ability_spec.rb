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
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation.create!(group: touren_group,
        person: person)
    end

    it "is able to create tours in section" do
      expect(ability).to be_able_to(:create, Event::Tour.new(groups: [groups(:bluemlisalp)]))
    end

    it "is not able to create events in group" do
      expect(ability).not_to be_able_to(:create, Event.new(groups: [touren_group]))
    end

    it "is not able to create tours in ortsgruppe" do
      expect(ability).not_to be_able_to(:create,
        Event::Tour.new(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)]))
    end

    it "is not able to create tours in other section" do
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
        it "is able to create in section" do
          expect(ability).to be_able_to(:create, event_class.new(groups: [groups(:bluemlisalp)]))
        end

        it "is not able to create in group" do
          expect(ability).not_to be_able_to(:create, event_class.new(groups: [touren_group]))
        end

        it "is not able to create in ortsgruppe" do
          expect(ability).not_to be_able_to(:create,
            event_class.new(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)]))
        end

        it "is not able to create in other section" do
          expect(ability).not_to be_able_to(:create, event_class.new(groups: [groups(:matterhorn)]))
        end

        [:update, :assign_tags, :manage_attachments].each do |action|
          it "is able to #{action} if created by themselves" do
            expect(ability).to be_able_to(action, event_class.new(groups: [groups(:bluemlisalp)],
              creator: person))
          end

          it "is not able to #{action} if created by someone else" do
            expect(ability).not_to be_able_to(action, event_class.new(groups: [groups(:bluemlisalp)],
              creator: Fabricate(:person)))
          end
        end
      end
    end
  end

  describe "for_assigned_freigabe_komitee" do
    let(:tour) { events(:section_tour) }
    let!(:pruefer_role) { Group::FreigabeKomitee::Pruefer.create!(group: freigabe_komitee, person: person) }

    context "sektion level freigabe komitee" do
      let(:freigabe_komitee) { groups(:bluemlisalp_freigabekomitee) }

      it "is able to update tour with pruefer role in assigned freigabe komitee" do
        expect(ability).to be_able_to(:update, tour)
      end

      it "is able to update tour from ortsgruppe in the same sektion" do
        tour.update!(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)])

        expect(ability).to be_able_to(:update, tour)
      end

      it "is not able to update tour without pruefer role in assigned freigabe komitee" do
        pruefer_role.destroy!

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "is not able to update tour when freigabe komitee is not assigned to tour" do
        event_approval_commission_responsibilities(:bluemlisalp_wandern_kinder_subito).destroy!
        event_approval_commission_responsibilities(:bluemlisalp_wandern_familien_subito).destroy!

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "is not able to update tour from another sektion" do
        tour.update!(groups: [groups(:matterhorn)])

        expect(ability).not_to be_able_to(:update, tour)
      end
    end

    context "ortsgruppe level freigabe komitee" do
      let(:freigabe_komitee) { groups(:bluemlisalp_ortsgruppe_ausserberg_freigabe_komitee) }

      before do
        tour.update!(groups: [groups(:bluemlisalp_ortsgruppe_ausserberg)])
      end

      it "is able to update tour with pruefer role in assigned freigabe komitee" do
        expect(ability).to be_able_to(:update, tour)
      end

      it "is not able to update tour from sektion when part of ortsgruppe freigabekomitee" do
        tour.update!(groups: [groups(:bluemlisalp)])

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "is not able to update tour without pruefer role in assigned freigabe komitee" do
        pruefer_role.destroy!

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "is not able to update tour when freigabe komitee is not assigned to tour" do
        event_approval_commission_responsibilities(:bluemlisalp_ortsgruppe_ausserberg_wandern_kinder_subito).destroy!
        event_approval_commission_responsibilities(:bluemlisalp_ortsgruppe_ausserberg_wandern_familien_subito).destroy!

        expect(ability).not_to be_able_to(:update, tour)
      end

      it "is not able to update tour from another ortsgruppe" do
        another_ortsgruppe = Fabricate(Group::Ortsgruppe.sti_name, parent: groups(:matterhorn), foundation_year: 2000)
        tour.update!(groups: [another_ortsgruppe])

        expect(ability).not_to be_able_to(:update, tour)
      end
    end
  end
end
