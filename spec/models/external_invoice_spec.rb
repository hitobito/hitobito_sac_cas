# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe ExternalInvoice do
  context "destroy" do
    let(:participation) { Fabricate(:event_participation) }
    let!(:external_invoice) { Fabricate(:external_invoice, link: participation) }

    it "is prevented if associated external_invoices exist" do
      expect { participation.destroy }.not_to change { Event::Participation.count }
      expect(participation.errors.full_messages[0]).to eq "Datensatz kann nicht gelöscht werden, " \
        "da abhängige Rechnungen existieren."
    end

    it "succeeds if no associated external_invoices exists" do
      external_invoice.destroy!
      expect { participation.destroy }.to change { Event::Participation.count }.by(-1)
    end
  end
end
