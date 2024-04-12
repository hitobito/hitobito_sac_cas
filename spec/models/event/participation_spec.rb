# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::Participation do

  describe '::callbacks' do
    subject(:participation) { Fabricate(:event_participation, event: events(:top_course)) }

    [
      {state: :canceled, canceled_at: Time.zone.today},
      {state: :annulled}
    ].each do |attrs|
      it "sets previous state when updating to #{attrs[:state]}" do
        expect do
          participation.update!(attrs)
        end.to change { participation.reload.previous_state }.from(nil).to('assigned')
      end
    end
  end

  describe '#particpant_cancelable?' do
    let(:course) do
      Fabricate.build(:sac_course).tap { |e| e.dates.build(start_at: 10.days.from_now) }
    end

    subject(:participation) { Fabricate.build(:event_participation, event: course) }

    it 'may not be canceled by participant if applications are not cancelable' do
      course.applications_cancelable = false
      expect(participation).not_to be_particpant_cancelable
    end

    it 'may not be canceled by participant if course is in annulled state' do
      course.applications_cancelable = true
      course.state = 'annulled'
      expect(participation).not_to be_particpant_cancelable
    end

    it 'may not be canceled by participant if course starts today' do
      course.applications_cancelable = true
      course.state = 'application_open'
      course.dates.first.start_at = Time.zone.now
      expect(participation).not_to be_particpant_cancelable
    end

    it 'may not be canceled by participant if course started in the past' do
      course.applications_cancelable = true
      course.state = 'application_open'
      course.dates.first.start_at = 1.day.ago
      expect(participation).not_to be_particpant_cancelable
    end

    it 'may not be canceled by participant if any date is in the past' do
      course.applications_cancelable = true
      course.state = 'application_open'
      course.dates.build.start_at = 1.day.from_now
      course.dates.build.start_at = 1.day.ago
      expect(participation).not_to be_particpant_cancelable
    end


    it 'may be canceled otherwise' do
      course.applications_cancelable = true
      course.state = 'application_open'
      course.dates.first.start_at = 1.day.from_now
      expect(participation).to be_particpant_cancelable
    end
  end

  describe '#subsidizable?' do
    let(:course) { Fabricate.build(:sac_course, applications_cancelable: true) }
    subject(:participation) { Fabricate.build(:event_participation, event: course) }

    def build_role(key, role)
      group = groups(key)
      types = group.role_types.collect { |rt| [rt.to_s.demodulize, rt.sti_name] }.to_h
      participation.person.roles.build(type: types.fetch(role), group: group)
    end

    it 'is false when person has no role' do
      expect(participation).not_to be_subsidizable
    end

    [
      [:bluemlisalp_mitglieder, 'Mitglied', true],
      [:bluemlisalp_neuanmeldungen_nv, 'Neuanmeldung', true],
      [:bluemlisalp_neuanmeldungen_sektion, 'Neuanmeldung', true],
    ].each do |group, role|
      it "is true if person has #{role} in #{group}" do
        build_role(group, role)
        expect(participation).to be_subsidizable
      end
    end
  end
end
