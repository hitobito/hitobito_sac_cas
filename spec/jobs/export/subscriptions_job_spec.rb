# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Export::SubscriptionsJob do
  let(:user) { people(:admin) }
  let(:mailing_list) { mailing_lists(:newsletter) }

  context 'with recipients param' do
    subject(:job) do
      described_class.new(:csv, user.id, mailing_list.id, recipients: true, filename: 'dummy')
    end

    it 'uses SacRecipients tabular export' do
      expect(Export::Tabular::People::SacRecipients).to receive(:export)
      job.perform
    end
  end
end
