# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TokenAbility do
  subject { ability }

  let(:root) { groups(:root) }
  let(:bluemlisalp) { groups(:bluemlisalp) }

  let(:ability) { TokenAbility.new(token) }

  describe "read and write on invoice" do
    let!(:external_invoice) { Fabricate(:external_invoice, person: people(:mitglied)) }

    context "with token on root layer" do
      let(:token) { service_tokens(:permitted_root_layer_token) }

      it "can read and update invoice" do
        expect(ExternalInvoice.accessible_by(ability)).to eq [external_invoice]
        expect(ability).to be_able_to(:read, external_invoice)
        expect(ability).to be_able_to(:update, external_invoice)
      end
    end

    context "with token on section layer" do
      let(:token) { ServiceToken.create!(name: "bluemli", layer: bluemlisalp, invoices: true) }

      it "cannot read or update invoice" do
        expect(ExternalInvoice.accessible_by(ability)).to be_empty
        expect(ability).not_to be_able_to(:read, external_invoice)
        expect(ability).not_to be_able_to(:update, external_invoice)
      end
    end
  end
end
