# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe ExternalTraining do

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

end
