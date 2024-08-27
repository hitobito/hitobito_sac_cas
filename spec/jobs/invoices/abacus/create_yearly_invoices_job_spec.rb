# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::Abacus::CreateYearlyInvoicesJob do
  let(:params) { {invoice_year:, invoice_date:, send_date:, role_finish_date:} }
  let(:invoice_year) { nil }
  let(:invoice_date) { nil }
  let(:send_date) { nil }
  let(:role_finish_date) { nil }
  let(:subject) { described_class.new(**params) }

  describe "#enqueue!" do
    it "will create a job and raise if there is already one running" do
      expect { subject.enqueue! }.to change(Delayed::Job, :count).by(1)
      expect { subject.enqueue! }.to raise_error("There is already a job running")
    end
  end
end
