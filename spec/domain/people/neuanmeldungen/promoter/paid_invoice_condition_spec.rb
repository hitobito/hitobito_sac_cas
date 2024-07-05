# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::Neuanmeldungen::Promoter::PaidInvoiceCondition do
  context "::satisfied?" do
    let(:role) { roles(:mitglied) }

    subject { described_class.new(role) }

    it "is true" do
      expect(subject.satisfied?).to eq true
    end
  end
end
