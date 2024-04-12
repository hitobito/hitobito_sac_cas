# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::ParticipationAbility do

  def build(group, person: people(:admin), event: nil)
    event ||= Event::Course.new(groups: [groups(group)], id: -1, supports_applications: true)
    Event::Participation.new(event: event, person: person, application_id: -1)
  end

  def build_role(key, role)
    group = groups(key)
    types = group.role_types.collect { |rt| [rt.to_s.demodulize, rt.sti_name] }.to_h
    Fabricate(types.fetch(role), group: group)
  end

  subject(:ability) { Ability.new(role.person) }

  context 'any' do
    let(:top_course) { events(:top_course) }
    let(:participation) { build(:bluemlisalp_funktionaere, event: top_course) }
    let(:role) { build_role(:bluemlisalp_funktionaere, 'Andere') }

    describe 'summon' do
      it 'leader may summon' do
        build(:bluemlisalp_funktionaere, event: top_course, person: role.person).tap(&:save!)
          .roles.create!(type: Event::Role::Leader.sti_name)
        expect(subject).to be_able_to(:summon, participation)
      end

      it 'participant may not summon' do
        build(:bluemlisalp_funktionaere, event: top_course, person: role.person).tap(&:save!)
          .roles.create!(type: Event::Role::Participant.sti_name)
        expect(subject).not_to be_able_to(:summon, participation)
      end
    end

    describe 'cancel'  do
      it 'may not cancel others' do
        expect(subject).not_to be_able_to(:cancel, participation)
      end

      it 'may cancel her own' do
        participation = build(:bluemlisalp_funktionaere, event: top_course, person: role.person)
        expect(subject).to be_able_to(:cancel, participation)
      end
    end
  end

  context 'layer_and_below_full' do
    context 'root' do
      let(:role) { build_role(:geschaeftsstelle, 'Mitarbeiter') }

      [:summon, :cancel].each do |action|
        it "may #{action} for event in layer" do
          expect(subject).to be_able_to(action, build(:root))
        end

        it "may not #{action} for event in lower layer" do
          expect(subject).not_to be_able_to(action, build(:bluemlisalp_funktionaere))
        end
      end
    end

    context 'sektion' do
      let(:role) { build_role(:bluemlisalp_funktionaere, 'Administration') }

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

  context 'group_full' do
    let(:role) { build_role(:matterhorn_tourenkommission, 'TourenchefWinter') }

    [:summon, :cancel].each do |action|
      it "may not #{action} on group above" do
        expect(subject).not_to be_able_to(action, build(:matterhorn))
      end

      it "may #{action} on group" do
        expect(subject).to be_able_to(action, build(:matterhorn_tourenkommission))
      end
    end
  end
end
