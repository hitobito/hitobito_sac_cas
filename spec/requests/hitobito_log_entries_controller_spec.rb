# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe HitobitoLogEntriesController, type: :request do
  let(:user) { people(:admin) }

  before { sign_in(user) }

  describe "GET hitobito_log_entries/rechnungen" do
    let(:invoice) { Fabricate(:external_invoice) }
    let!(:log_entry) { HitobitoLogEntry.create!(category: "rechnungen", level: :error, message: "something went wrong", subject: invoice) }

    it "renders ExternalInvoices with a correct link" do
      get "/de/hitobito_log_entries/rechnungen"
      expect(response).to be_successful
      expect(response.body).to include("a href=\"/de/external_invoices/#{invoice.id}")
    end
  end
end
