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

  describe "index_external_invoices on Group" do
    context :root do
      let(:token) { service_tokens(:permitted_root_layer_token) }

      it "can index invoices on root group" do
        expect(ability).to be_able_to(:index_external_invoices, root)
      end

      it "can index invoices on bluemlisalp" do
        expect(ability).to be_able_to(:index_external_invoices, bluemlisalp)
      end
    end

    context :bluemlisalp do
      let(:token) { service_tokens(:permitted_bluemlisalp_layer_token) }

      it "cannot index invoices on root group" do
        expect(ability).not_to be_able_to(:index_external_invoices, root)
      end

      it "can index invoices on bluemlisalp" do
        expect(ability).to be_able_to(:index_external_invoices, bluemlisalp)
      end
    end
  end

  describe "read and write on invoice" do
    def create_invoice_for(group)
      Fabricate(:external_invoice, link: group, person: people(:mitglied))
    end

    context :root do
      let(:token) { service_tokens(:permitted_root_layer_token) }

      it "can read and update invoice on bluemlisalp group" do
        invoice = create_invoice_for(root)
        expect(ExternalInvoice.accessible_by(ability)).to eq [invoice]
        expect(ability).to be_able_to(:read, invoice)
        expect(ability).to be_able_to(:update, invoice)
      end
    end

    context :bluemlisalp do
      let(:token) { service_tokens(:permitted_bluemlisalp_layer_token) }

      it "cannot read or update invoice on root group" do
        invoice = create_invoice_for(root)
        expect(ExternalInvoice.accessible_by(ability)).to be_empty
        expect(ability).not_to be_able_to(:read, invoice)
        expect(ability).not_to be_able_to(:update, invoice)
      end

      it "can read and update invoice on bluemlisalp group" do
        invoice = create_invoice_for(bluemlisalp)
        expect(ExternalInvoice.accessible_by(ability)).to eq [invoice]
        expect(ability).to be_able_to(:read, invoice)
        expect(ability).to be_able_to(:update, invoice)
      end
    end
  end
end
