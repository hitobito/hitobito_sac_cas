# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ParticipationAbility do
  def build(group, person: people(:admin), event: nil)
    event ||= Event::Course.new(groups: [groups(group)], id: -1, supports_applications: true)
    Event::Participation.new(event: event, person: person, application_id: -1)
  end

  def build_participation_role(person, role_type, participation: nil, self_employed: false)
    build(:bluemlisalp_funktionaere, event: top_course, person: person).tap(&:save!)
      .roles.create!(type: role_type, participation: participation)
  end

  def build_role(key, role)
    group = groups(key)
    types = group.role_types.collect { |rt| [rt.to_s.demodulize, rt.sti_name] }.to_h
    Fabricate(types.fetch(role), group: group)
  end

  subject(:ability) { Ability.new(role.person.reload) }

  context "any" do
    let(:top_course) { events(:top_course) }
    let(:participation) { build(:bluemlisalp_funktionaere, event: top_course) }
    let(:role) { build_role(:bluemlisalp_funktionaere, "Andere") }

    context "leader" do
      let(:role_type) { Event::Course::Role::Leader.sti_name }

      before do
        build_participation_role(role.person, role_type)
      end

      it "cannot assign" do
        expect(subject).not_to be_able_to(:assign, participation)
      end

      it "can be absent" do
        expect(subject).to be_able_to(:absent, participation)
      end

      it "can attend" do
        expect(subject).to be_able_to(:attend, participation)
      end

      it "cannot summon" do
        expect(subject).not_to be_able_to(:summon, participation)
      end
    end

    context "assistant leader" do
      let(:role_type) { Event::Course::Role::AssistantLeader.sti_name }

      before do
        build_participation_role(role.person, role_type)
      end

      it "cannot assign" do
        expect(subject).not_to be_able_to(:assign, participation)
      end

      it "can be absent" do
        expect(subject).to be_able_to(:absent, participation)
      end

      it "can attend" do
        expect(subject).to be_able_to(:attend, participation)
      end

      it "cannot summon" do
        expect(subject).not_to be_able_to(:summon, participation)
      end
    end

    context "participant" do
      let(:role_type) { Event::Course::Role::Participant.sti_name }

      before do
        build_participation_role(role.person, role_type)
      end

      it "cannot summon" do
        expect(subject).not_to be_able_to(:summon, participation)
      end
    end

    describe "leader_settlement" do
      let(:top_course) { events(:top_course) }
      let(:role) { build_role(:bluemlisalp_mitglieder, "Mitglied") }
      let(:participation) { build(:bluemlisalp_mitglieder, event: top_course, person: role.person) }

      context "not self employed" do
        before do
          participation.save!
          participation.roles.create!(type: Event::Course::Role::Leader, self_employed: false)
        end

        it "may not leader_settlement when participation is not self employed" do
          expect(subject).not_to be_able_to(:leader_settlement, participation)
        end
      end

      context "leader" do
        before do
          participation.save!
          participation.roles.build(type: Event::Course::Role::Leader, self_employed: true)
        end

        it "may leader_settlement her own" do
          expect(subject).to be_able_to(:leader_settlement, participation)
        end

        it "may not leader_settlement other participations" do
          other_participation = build(:bluemlisalp_mitglieder, event: top_course)
          expect(subject).not_to be_able_to(:leader_settlement, other_participation)
        end
      end

      context "assistant leader" do
        before do
          participation.save!
          participation.roles.build(type: Event::Course::Role::AssistantLeader, self_employed: true)
        end

        it "may leader_settlement her own" do
          expect(subject).to be_able_to(:leader_settlement, participation)
        end

        it "may not leader_settlement other participations" do
          other_participation = build(:bluemlisalp_mitglieder, event: top_course)
          expect(subject).not_to be_able_to(:leader_settlement, other_participation)
        end
      end

      context "layer and below full" do
        let(:role) { roles(:admin) }

        before do
          participation.save!
          participation.roles.build(type: Event::Course::Role::AssistantLeader, self_employed: true)
        end

        it "may leader_settlement on anty participations" do
          expect(subject).to be_able_to(:leader_settlement, participation)
        end
      end
    end

    describe "reactivate" do
      let(:top_course) { events(:top_course) }
      let(:role) { build_role(:bluemlisalp_mitglieder, "Mitglied") }
      let(:participation) { build(:bluemlisalp_mitglieder, event: top_course, person: role.person) }

      it "may not reactivate participation as non course admin" do
        expect(subject).not_to be_able_to(:reactivate, participation)
      end

      context "layer and below full" do
        let(:role) { roles(:admin) }

        before do
          participation.save!
          participation.roles.build(type: Event::Course::Role::AssistantLeader, self_employed: true)
        end

        it "may reactivate on any participations" do
          expect(subject).to be_able_to(:reactivate, participation)
        end
      end
    end

    describe "cancel" do
      it "may not cancel others" do
        expect(subject).not_to be_able_to(:cancel, participation)
      end

      it "may cancel her own" do
        participation = build(:bluemlisalp_funktionaere, event: top_course, person: role.person)
        expect(subject).to be_able_to(:cancel, participation)
      end
    end

    describe "update" do
      it "may not update others" do
        expect(subject).not_to be_able_to(:update, participation)
      end

      it "may update her own" do
        participation = build(:bluemlisalp_funktionaere, event: top_course, person: role.person)
        expect(subject).to be_able_to(:update, participation)
      end
    end

    describe "destroy" do
      it "may not destroy others" do
        expect(subject).not_to be_able_to(:destroy, participation)
      end

      it "may not destroy own" do
        participation = build(:bluemlisalp_funktionaere, event: top_course, person: role.person)
        expect(subject).not_to be_able_to(:destroy, participation)
      end
    end

    describe "edit_actual_days" do
      context "with participations_full event role" do
        let(:own_participation) { build(:bluemlisalp_funktionaere, event: top_course, person: role.person) }

        before do
          Event::Course::Role::Leader.create!(participation: own_participation)
        end

        it "may edit_actual_days others" do
          expect(subject).to be_able_to(:edit_actual_days, participation)
        end

        it "may edit_actual_days own" do
          expect(subject).to be_able_to(:edit_actual_days, own_participation)
        end
      end

      context "without participations_full event role" do
        it "may not edit_actual_days others" do
          expect(subject).not_to be_able_to(:edit_actual_days, participation)
        end

        it "may not edit_actual_days own" do
          participation = build(:bluemlisalp_funktionaere, event: top_course, person: role.person)
          expect(subject).not_to be_able_to(:edit_actual_days, participation)
        end
      end
    end
  end

  context "layer_and_below_full" do
    context "root" do
      let(:role) { build_role(:geschaeftsstelle, "Mitarbeiter") }

      [:summon, :cancel].each do |action|
        it "may #{action} for event in layer" do
          expect(subject).to be_able_to(action, build(:root))
        end

        it "may not #{action} for event in lower layer" do
          expect(subject).not_to be_able_to(action, build(:bluemlisalp_funktionaere))
        end
      end
    end

    context "sektion" do
      let(:role) { build_role(:bluemlisalp_funktionaere, "Administration") }

      [:summon, :cancel].each do |action|
        it "may #{action} for event in layer" do
          expect(subject).to be_able_to(action, build(:bluemlisalp_funktionaere))
        end

        it "may #{action} for event in uppper layer" do
          expect(subject).not_to be_able_to(action, build(:root))
        end
      end
    end
  end
end
