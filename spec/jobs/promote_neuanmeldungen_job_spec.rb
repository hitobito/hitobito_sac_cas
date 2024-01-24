# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe PromoteNeuanmeldungenJob do
  it 'calls People::Neuanmeldungen::Promoter#call' do
    expect(People::Neuanmeldungen::Promoter).to receive(:new).and_call_original
    expect_any_instance_of(People::Neuanmeldungen::Promoter).to receive(:call)
    subject.perform
  end
end
