# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Qualification do
  it 'is invalid when finish_at is before start_at' do
    qualification = Fabricate.build(:qualification, start_at: 1.day.ago, finish_at: 1.month.ago)

    expect(qualification).to_not be_valid
    expect(qualification.errors.full_messages).to eq(["Bis muss nach Seit liegen"])
  end

  it 'is valid when finish_at is after start_at' do
    qualification = Fabricate.build(:qualification, start_at: 1.day.ago, finish_at: 1.month.from_now)

    expect(qualification).to be_valid
    expect(qualification.errors.full_messages).to be_empty
  end

  it 'is valid when start_at is in the future' do
    qualification = Fabricate.build(:qualification, start_at: 1.day.from_now)

    expect(qualification).to be_valid
  end

  context 'with qualifications_controller validation context' do
    it 'is invalid when start_at is in the future' do
      qualification = Fabricate.build(:qualification, start_at: 1.day.from_now)

      expect(qualification).to_not be_valid(:qualifications_controller)
      expect(qualification.errors.full_messages[0]).to eq('Seit muss in der Vergangenheit liegen')
    end
  end
end
