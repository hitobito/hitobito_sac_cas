# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe ExternalInvoice do
  describe "#destroy" do
    let!(:participation) { Fabricate(:event_participation) }

    context "with associated external_invoice" do
      before { Fabricate(:external_invoice, link: participation) }

      it "is prevented" do
        expect { participation.destroy }.not_to change { Event::Participation.count }
        # rubocop:todo Layout/LineLength
        expect(participation.errors.full_messages[0]).to eq "Datensatz kann nicht gelöscht werden, " \
          "da abhängige Rechnungen existieren."
        # rubocop:enable Layout/LineLength
      end
    end

    context "without associated external_invoice" do
      it "succeeds" do
        expect { participation.destroy }.to change { Event::Participation.count }.by(-1)
      end
    end
  end
end
