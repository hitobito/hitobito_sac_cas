# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::ParticipationAbility do

  def build(group, person: people(:admin), event: nil)
    event ||= Event::Course.new(groups: [groups(group)])
    Event::Participation.new(event: event, person: person)
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

    it 'event leader may summon' do
      build(:bluemlisalp_funktionaere, event: top_course, person: role.person).tap(&:save!)
        .roles.create!(type: Event::Role::Leader.sti_name)
      expect(subject).to be_able_to(:summon, participation)
    end

    it 'event participant may not summon' do
      build(:bluemlisalp_funktionaere, event: top_course, person: role.person).tap(&:save!)
        .roles.create!(type: Event::Role::Participant.sti_name)
      expect(subject).not_to be_able_to(:summon, participation)
    end
  end

  context 'layer_and_below_full' do
    context 'root' do
      let(:role) { build_role(:geschaeftsstelle, 'Mitarbeiter') }

      it 'may summon for event in layer' do
        expect(subject).to be_able_to(:summon, build(:root))
      end

      it 'may not summon for event in lower layer' do
        expect(subject).not_to be_able_to(:summon, build(:bluemlisalp_funktionaere))
      end
    end

    context 'sektion' do
      let(:role) { build_role(:bluemlisalp_funktionaere, 'Administration') }

      it 'may summon for event in layer' do
        expect(subject).to be_able_to(:summon, build(:bluemlisalp_funktionaere))
      end

      it 'may summon for event in uppper layer' do
        expect(subject).not_to be_able_to(:summon, build(:root))
      end
    end
  end

  context 'group_full' do
    let(:role) { build_role(:matterhorn_tourenkommission, 'TourenchefWinter') }

    it 'may not summon on group above' do
      expect(subject).not_to be_able_to(:summon, build(:matterhorn))
    end

    it 'may summon on group' do
      expect(subject).to be_able_to(:summon, build(:matterhorn_tourenkommission))
    end
  end
end
