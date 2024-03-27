# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe ExternalTraining do
  let(:date) { Date.new(2024, 3, 26) }

  it 'is invalid when finish_at is before start_at' do
    external_training = Fabricate.build(:external_training, person: people(:mitglied), start_at: 1.day.ago, finish_at: 1.month.ago)

    expect(external_training).to_not be_valid
    expect(external_training.errors.full_messages).to eq(["Enddatum muss nach #{external_training.start_at.strftime('%d.%m.%Y')} sein"])
  end

  it 'is valid when finish_at is after start_at' do
    external_training = Fabricate.build(:external_training, person: people(:mitglied), start_at: 1.day.ago, finish_at: 1.month.from_now)

    expect(external_training).to be_valid
    expect(external_training.errors.full_messages).to be_empty
  end

  describe '.between' do
    it 'returns training within validity period' do
      Fabricate(:external_training, start_at: date, finish_at: date + 1.day)
      expect(ExternalTraining.between(date, date)).to have(1).item
      expect(ExternalTraining.between(date, date + 1.day)).to have(1).item
      expect(ExternalTraining.between(date - 1.day, date)).to have(1).item
      expect(ExternalTraining.between(date - 2.days, date)).to have(1).item
      expect(ExternalTraining.between(date - 2.days, date - 1.day)).to be_empty
      expect(ExternalTraining.between(date + 1.days, date + 2.days)).to have(1).item
      expect(ExternalTraining.between(date + 2.days, date + 2.days)).to be_empty
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
      expect(ExternalTraining.new(start_at: date).start_date).to eq date
    end

    it '#qualification_date returns finish_at' do
      expect(ExternalTraining.new(finish_at: date).qualification_date).to eq date
    end
  end
end
