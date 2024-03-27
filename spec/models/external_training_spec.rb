# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe ExternalTraining do
  let(:today) { Date.new(2024, 3, 26) }

  describe 'validations' do

    def build(start_at:, finish_at: )
      Fabricate.build(:external_training, person: people(:mitglied), start_at: start_at, finish_at: finish_at)
    end

    it 'is invalid when finish_at is before start_at' do
      external_training = build(start_at: today, finish_at: today - 1.day)
      expect(external_training).to_not be_valid
      expect(external_training.errors.full_messages).to eq(
        ["Enddatum muss #{external_training.start_at.strftime('%d.%m.%Y')} oder danach sein"]
      )
    end

    it 'is valid when finish_at is after start_at' do
      external_training = build(start_at: today, finish_at: today + 1.day)
      expect(external_training).to be_valid
    end

    it 'is valid when finish_at is on start_at' do
      external_training = build(start_at: today, finish_at: today)
      expect(external_training).to be_valid
    end
  end

  describe '.between' do
    it 'returns training within validity period' do
      Fabricate(:external_training, start_at: today, finish_at: today + 1.day)
      expect(ExternalTraining.between(today, today)).to have(1).item
      expect(ExternalTraining.between(today, today + 1.day)).to have(1).item
      expect(ExternalTraining.between(today - 1.day, today)).to have(1).item
      expect(ExternalTraining.between(today - 2.days, today)).to have(1).item
      expect(ExternalTraining.between(today - 2.days, today - 1.day)).to be_empty
      expect(ExternalTraining.between(today + 1.days, today + 2.days)).to have(1).item
      expect(ExternalTraining.between(today + 2.days, today + 2.days)).to be_empty
    end
  end

  describe 'compatibility methods with events' do
    it '#to_s returns name' do
      expect(ExternalTraining.new(name: 'test').to_s).to eq 'test'
    end

    it '#kind returns event_kind' do
      kind = event_kinds(:ski_course)
      expect(ExternalTraining.new(event_kind: kind).kind).to eq kind
    end

    it '#start_date returns start_at' do
      expect(ExternalTraining.new(start_at: today).start_date).to eq today
    end

    it '#qualification_today returns finish_at' do
      expect(ExternalTraining.new(finish_at: today).qualification_date).to eq today
    end
  end
end
